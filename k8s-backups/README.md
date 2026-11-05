# k8s-backups

Owns the S3 bucket and IAM identity used by VolSync's restic mover to back up
Kubernetes PVCs. The bucket is intentionally generic: restic/VolSync data lives under
`volsync/`, leaving room for other backup types later without another bucket.

The restic user is `k8s-backups-restic`. It can read and write only
`s3://kevindurb-k8s-backups/volsync/*`, and its effective permissions are capped by
`k8s-backups-restic-boundary`, which is created in `../bootstrap/` so the CI role cannot
raise it.

## State

State lives at `s3://kevindurb-tfstate/k8s-backups/terraform.tfstate`, configured in
`backend.tf`. The access key is deliberately **not** managed as an
`aws_iam_access_key` resource: that would put the secret key into Terraform state and
every historical state version. Instead, `terraform_data.restic_key` runs
`scripts/ensure-restic-key.sh`, which creates the key and writes it straight to SSM.

## Bucket layout

Each PVC gets its own restic repository, because VolSync does not support shared
repositories. The per-PVC path is:

```
s3:s3.us-east-1.amazonaws.com/kevindurb-k8s-backups/volsync/<namespace>/<pvc>
```

The `restic_repository_prefix` output gives the part before `/<namespace>/<pvc>`.

S3 bucket names are globally unique. If `kevindurb-k8s-backups` is unavailable, change
`bucket_name` here and `k8s_backups_bucket_name` in `../bootstrap/` together.

## Access key

The canonical copy is the SSM SecureString:

```
/k8s-backups/volsync/restic/s3-access-key
```

Its value is JSON:

```json
{
  "access_key_id": "...",
  "secret_access_key": "...",
  "version": 1
}
```

Read it with admin credentials:

```sh
aws ssm get-parameter \
  --name /k8s-backups/volsync/restic/s3-access-key \
  --with-decryption \
  --query Parameter.Value \
  --output text | jq .
```

The Kubernetes copy is a per-PVC `restic-config` SealedSecret in `kevindurb/k8s`. The
cluster does not read SSM at runtime. See `kevindurb/k8s/docs/backups.md`.

The key script runs automatically on `terraform apply`. It is idempotent: if the
parameter already holds the requested version and the access key is active, it exits
without touching anything. If the SSM write fails, it deletes the newly created key.

### Rotation

1. Bump `restic_key_version` and apply. The script creates a second key, writes it to
   SSM, and leaves the old key active.
2. Reseal every per-PVC `restic-config` SealedSecret with the new key.
3. Verify a backup and a restore.
4. Delete the old access key:

   ```sh
   aws iam list-access-keys --user-name k8s-backups-restic
   aws iam delete-access-key \
     --user-name k8s-backups-restic \
     --access-key-id <old-key-id>
   ```

AWS allows two access keys per user; the script refuses to create a third. Inactive
keys are removed automatically.

If Terraform state is lost or the script needs to be run outside CI, run it directly
with the same environment variables:

```sh
IAM_USER=k8s-backups-restic \
SSM_PARAM=/k8s-backups/volsync/restic/s3-access-key \
REGION=us-east-1 \
KEY_VER=1 \
./scripts/ensure-restic-key.sh
```

If the parameter is deleted outside Terraform, force the script to run again with:

```sh
terraform apply -replace=terraform_data.restic_key
```

## Why the bucket is configured this way

- **No versioning.** Restic's `prune` deletes pack files. S3 versioning would keep every
  deleted pack as a noncurrent version and inflate the bill. Restic's own retention is
  the version history.
- **No Object Lock.** It would stop deletion but also break `prune`. Revisit only with
  a different retention design.
- **SSE-S3.** Restic encrypts on the client; SSE-S3 is defense in depth.
- **Public access blocked and TLS-only.** Standard bucket hardening.
- **Abort incomplete multipart uploads after 7 days.** A mover that dies can leave one
  behind; restic never resumes it.
- **`prevent_destroy` and `force_destroy = false`.** The bucket holds the only off-site
  copy of every stateful volume. A Terraform destroy must fail rather than delete it.

## CI permissions

The existing `tf_plan` / `tf_apply` roles get additional inline policies in
`../bootstrap/k8s_backups.tf`:

- Plan reads the bucket configuration and the restic user. It has no SSM access.
- Apply manages the bucket settings, the restic user and its inline policy, the access
  key, and the SSM parameter. It has no object-level S3 permissions, so the CI role
  cannot delete backup data.
- Apply cannot change the restic user's permissions boundary.

Apply `../bootstrap/` locally before this root: the boundary must exist before the user
is created, and the new role permissions must exist before CI can plan here.

## Destroying

The bucket has `prevent_destroy`, and the IAM user cannot be deleted while it has access
keys. To decommission deliberately, remove the key and the bucket policy, empty the
bucket, delete the access key, then remove the `prevent_destroy` block and apply.
