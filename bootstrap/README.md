# bootstrap

The layer that makes every other root possible: the state bucket, the GitHub OIDC
provider, and the roles CI assumes.

Run by hand, locally, exactly once. It is deliberately **not** in CI — it creates the
credentials CI would need to run it.

## State

There is no `backend` block here on purpose. Start with local state, then move it into
the bucket this root creates:

```sh
terraform init
terraform apply                       # local state, creates the bucket
# add backend "s3" pointing at the bucket that was just created
terraform init -migrate-state
```

After that, bootstrap's state lives in the bucket it manages. `prevent_destroy` on the
bucket plus `force_destroy = false` means the classic disaster — destroying the bucket
that holds the state of the thing that created the bucket — fails instead of succeeding.

## What it contains

- `aws_s3_bucket.tfstate` — versioning on (it is how you recover from a truncated state),
  SSE-S3, public access blocked, TLS-only bucket policy.
- `aws_iam_openid_connect_provider.github` — `token.actions.githubusercontent.com`,
  audience `sts.amazonaws.com`. **Import it instead of creating it** if it already exists
  in the account; there can only be one per URL.
- `aws_iam_role.tf_plan` — read-only on the state prefix. Used with `-lock=false` so it
  never needs to write.
- `aws_iam_role.tf_apply` — read/write on the state prefix, including
  `s3:DeleteObject` for `*.tflock`.

Both trust policies pin
`token.actions.githubusercontent.com:sub` to `repo:kevindurb/infra:ref:refs/heads/main`.
Never `repo:kevindurb/infra:*` — this repo is public.

`tf_apply` is deliberately broad. The trust policy and the `production` environment's
required reviewers are the actual controls, not a per-resource IAM policy that would be
rewritten every time a new AWS service shows up.

## Break-glass

Keep an admin path (SSO user or an admin API token) outside Terraform until the first
clean apply of every other root has landed.
