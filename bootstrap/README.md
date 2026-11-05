# bootstrap

The layer that makes every other root possible: the state bucket, the GitHub OIDC
provider, and the roles CI assumes.

Run by hand, locally, exactly once. It is deliberately **not** in CI — it creates the
credentials CI would need to run it.

## What it contains

| Resource | Name |
| --- | --- |
| `aws_s3_bucket.tfstate` | `kevindurb-tfstate` |
| `aws_iam_openid_connect_provider.github` | `token.actions.githubusercontent.com` |
| `aws_iam_role.tf_plan` | `tf_plan` |
| `aws_iam_role.tf_apply` | `tf_apply` |
| `aws_iam_role_policy.tf_plan` / `.tf_apply` | `tf_plan` / `tf_apply` (inline) |

The bucket has versioning on (it is how you recover from a truncated state), SSE-S3,
public access blocked, and a TLS-only bucket policy. `prevent_destroy` plus
`force_destroy = false` means the classic disaster — destroying the bucket that holds
the state of the thing that created the bucket — fails instead of succeeding.

Both roles trust GitHub OIDC with `aud = sts.amazonaws.com` and pin
`token.actions.githubusercontent.com:sub` to the exact immutable subject

```
repo:kevindurb@2565006/infra@1446549993:ref:refs/heads/main
```

GitHub adds the owner and repository IDs for every repository created after
2026-07-15 and there is no opt-out, so the name-only form
(`repo:kevindurb/infra:...`) never matches. The IDs are public and immutable, which is
stronger than names; the variables reject `*` and `?`. Never use a wildcard — this repo is
public.

`tf_plan` also accepts the exact same-repo PR subject
(`repo:kevindurb@2565006/infra@1446549993:pull_request`) because the plan job runs on
pull requests; fork PRs are skipped by the workflow.

`tf_apply` is different: jobs that declare a GitHub environment receive an
**environment-qualified** subject, so the role trusts exactly
`repo:kevindurb@2565006/infra@1446549993:environment:production`. The main-only
restriction for apply comes from the `production` environment's deployment branch policy,
together with its required reviewers — not from the `sub` claim. Both are exact matches;
no wildcard appears anywhere.

`tf_plan` can `GetObject` and `ListBucket`, so plans run with `-lock=false`; `tf_apply`
can `GetObject`, `PutObject` and `DeleteObject` on the state prefix, the last for the
`*.tflock` object `use_lockfile` creates.

**The OIDC provider is account-global and there can be only one per URL.** If the account
already has one, import it before the first apply rather than letting Terraform create a
second (which fails with `EntityAlreadyExists`):

```sh
aws iam list-open-id-connect-providers

terraform import \
  aws_iam_openid_connect_provider.github \
  arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
```

`thumbprint_list` is intentionally not set: GitHub's chain uses a root CA AWS trusts, so
no thumbprint is required, and omitting it keeps an imported provider from diffing
forever.

## State

State lives in `s3://kevindurb-tfstate/bootstrap/terraform.tfstate`, configured in
`backend.tf`:

```hcl
backend "s3" {
  bucket       = "kevindurb-tfstate"
  key          = "bootstrap/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
```

`use_lockfile` needs Terraform >= 1.11; there is no DynamoDB table. The bucket is
versioned, so the previous state is recoverable from S3 object versions.

The backend block could not exist for the first apply: the bucket cannot hold the state
of the run that creates it. That one-time migration has already been done. If the
account or bucket is ever rebuilt from scratch, the sequence is:

```sh
cd bootstrap

# 1. With no backend block: local state. Creates the bucket, the OIDC provider
#    and the roles.
terraform init
terraform plan
terraform apply

# 2. Add the block above to backend.tf.

# 3. Move the local state into the bucket that now exists.
terraform init -migrate-state      # answer yes

# 4. Confirm the remote state works and the plan is empty.
terraform plan

# 5. Only after step 4 passes, remove the pre-migration backup if present.
rm -f terraform.tfstate.backup
```

After the migration, every change to this root is a normal `terraform plan` /
`terraform apply` from `bootstrap/`, using credentials that can read and write the
bucket.

## Outputs

`terraform output` after the apply gives the values for the repository settings:

| Output | Used as |
| --- | --- |
| `state_bucket` | informational |
| `tf_plan_role_arn` | repository variable `AWS_PLAN_ROLE_ARN` |
| `tf_apply_role_arn` | repository variable `AWS_APPLY_ROLE_ARN` |
| `github_oidc_provider_arn` | informational |

Also set `AWS_REGION` (`us-east-1`), and create the `production` environment under
*Settings → Environments* with required reviewers so a merge alone cannot apply.

## Break-glass

Keep an admin path (SSO user or an admin API token) outside Terraform until the first
clean apply of every other root has landed.
