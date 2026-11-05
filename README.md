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
just plan tailnet   # needs AWS credentials + the Tailscale federated identity
just apply tailnet
just fmt
```

`bootstrap/` is run by hand exactly once and deliberately is not in CI: it creates the
bucket that holds every other root's state, and the roles CI assumes.

## Repository variables

The workflows read these from repository *variables* (not secrets — none of them are
secret):

| Variable | Used by |
| --- | --- |
| `AWS_REGION` | all |
| `AWS_PLAN_ROLE_ARN` | plan job (read-only on the state prefix) |
| `AWS_APPLY_ROLE_ARN` | apply job |

The apply job also targets a GitHub **environment** called `production`; add required
reviewers there so a merge alone is not enough to apply.

## Docs

- [`docs/tailnet.md`](docs/tailnet.md) — why the tailnet config lives here, what moved,
  and the rollout order.
