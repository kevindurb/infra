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
`token.actions.githubusercontent.com:sub` to
`repo:kevindurb/infra:ref:refs/heads/main`. Never `repo:kevindurb/infra:*` — this repo is
public. The apply role sits behind the `production` environment with required reviewers;
that and the trust policy are the controls, not a per-resource IAM policy.

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

There is no `backend` block here on purpose: the bucket cannot hold the state of the run
that creates it. `backend.tf` records where the block goes. The one-time sequence:

```sh
cd bootstrap

# 1. Local state. This creates the bucket, the OIDC provider and the roles.
terraform init
terraform plan
terraform apply

# 2. Add the backend block below to backend.tf (replace the commented one).

# 3. Move the local state into the bucket that now exists.
terraform init -migrate-state      # answer yes

# 4. Confirm the remote state works and the plan is empty.
terraform plan

# 5. Only after step 4 passes, remove the pre-migration backup if present.
rm -f terraform.tfstate.backup
```

The block for step 2:

```hcl
backend "s3" {
  bucket       = "kevindurb-tfstate"
  key          = "bootstrap/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
```

After step 5, bootstrap's state lives in the bucket it manages and every later change to
this root is a normal `terraform plan` / `terraform apply` from `bootstrap/`, using
credentials that can read and write that bucket.

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
