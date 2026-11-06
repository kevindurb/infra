# infra

Terraform for everything **outside** the Kubernetes cluster: the tailnet's control
plane today, AWS resources as they arrive.

The cluster itself is reconciled by Argo CD from
[`kevindurb/k8s`](https://github.com/kevindurb/k8s) — nothing here is applied by Argo.

## Root modules

| Root | Owns | State | Applied by |
| --- | --- | --- | --- |
| `bootstrap/` | state bucket, GitHub OIDC provider, CI roles | `bootstrap/terraform.tfstate`, in the bucket it creates | by hand, locally |
| `tailnet/` | Tailscale policy file, tailnet settings, DNS, Services | `tailnet/terraform.tfstate` | GitHub Actions |
| `k8s-backups/` | S3 bucket, IAM user and access key for restic/VolSync PVC backups | `k8s-backups/terraform.tfstate` | GitHub Actions |

Root modules sit at the top level and are **never nested** — state is per-directory, so a
root inside a root means `apply` from the parent silently does nothing. `modules/` is
reserved for shared child modules and is empty until something is used twice.

Roots are split by blast radius and change rate, not by provider: a root called `aws/`
would mix a key that must never be replaced with a throwaway instance, and every apply
would touch all of it.

## Prerequisites

- Terraform >= 1.11 (1.11 is where `use_lockfile` went GA; there is no DynamoDB table)
- `just`, `pre-commit`

## Usage

```sh
just check          # fmt + validate every root, no credentials needed
just plan tailnet   # needs AWS credentials + Tailscale credentials
just apply tailnet
just fmt
```

CI obtains both sets of credentials through GitHub OIDC. For a local plan, use AWS
credentials as usual and either `TAILSCALE_API_KEY`, or both
`TAILSCALE_OAUTH_CLIENT_ID` + `TAILSCALE_AUDIENCE` with a
`TAILSCALE_IDENTITY_TOKEN` that the provider can exchange.

`bootstrap/` is run by hand when the credential fabric changes and deliberately is not
in CI: it creates the bucket that holds every other root's state, the roles CI assumes,
and the generic IAM/S3/SSM permissions those roles use to manage Terraform-created
identities.

## Repository variables

The workflows read these from repository *variables* (not secrets — none of them are
secret):

| Variable | Used by |
| --- | --- |
| `AWS_REGION` | all |
| `AWS_PLAN_ROLE_ARN` | plan job (read-only on the state prefix) |
| `AWS_APPLY_ROLE_ARN` | apply job |
| `TAILSCALE_PLAN_OAUTH_CLIENT_ID` | plan job (read-only federated identity) |
| `TAILSCALE_PLAN_AUDIENCE` | plan job |
| `TAILSCALE_APPLY_OAUTH_CLIENT_ID` | apply job (write federated identity) |
| `TAILSCALE_APPLY_AUDIENCE` | apply job |

The apply job also targets a GitHub **environment** called `production`; add required
reviewers there so a merge alone is not enough to apply.

The current root manages only the policy file, so the Tailscale identities need only
`policy_file:read` for plan and `policy_file` for apply. Settings, DNS and Services are
still console-managed.

## Docs

- [`docs/tailnet.md`](docs/tailnet.md) — why the tailnet config lives here, what moved,
  and the rollout order.
- [`k8s-backups/README.md`](k8s-backups/README.md) — the restic/VolSync bucket, key
  storage, rotation, and restore notes.
