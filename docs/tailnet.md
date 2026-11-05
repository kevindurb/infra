# Moving the tailnet config into `infra`

Status: **scaffolded**. The repo structure exists; `bootstrap/` and `tailnet/` are empty
apart from `versions.tf`. This document is the design record and the rollout order.

## Why this repo

`tailscale/policy.hujson` was the only artifact in `kevindurb/k8s` that described the
whole tailnet — the routers, the travel lab, the workstation, the CI runners — rather
than the cluster. It was applied by its own workflow and had no Argo CD involvement, so
nothing tied it to the cluster repo except history.

Terraform also covers the parts of the tailnet that existed only in the admin console
(settings, DNS, Services) and gives us a `plan` that detects console drift.

## Decisions

| Decision | Choice |
| --- | --- |
| Repo | `kevindurb/infra`, public. The old repo lives on as `kevindurb/old-k8s-infra`. |
| Layout | Root modules at the top level, `modules/` reserved. No `stacks/` — Terraform Stacks is a distinct HCP Terraform feature. No `envs/prod/` — there is one environment. |
| Tool | Terraform (the whole tailnet, not just the ACL), replacing `gitops-acl-action`. |
| State | AWS S3 `kevindurb-tfstate`, `use_lockfile = true`, versioning on. |
| Auth | GitHub OIDC → AWS role for state; Tailscale **federated identity** for the provider. No stored secrets. |
| Device tags | **Manual.** Out of scope. |
| Tag-vocabulary drift check in `k8s` | **Deferred.** |

## Verified facts this depends on

- The Tailscale provider supports federated identity: `oauth_client_id` + `audience`
  with `permissions: id-token: write`, and discovers the GitHub OIDC token itself. No
  client secret. `scopes` is ignored in that mode.
- The provider preserves HuJSON comments on write, and validates the policy's `tests`
  section at **plan** time. `tailscale_acl` overwrites the entire policy file.
- `use_lockfile` needs Terraform >= 1.11. AWS S3 supports it via conditional writes;
  Backblaze B2 does not (501 on the lock object), so B2 is not an option.
- Resources that must **not** be adopted, because they put secrets in state:
  `tailscale_oauth_client`, `tailscale_tailnet_key`, `tailscale_webhook`. Keeping state
  secret-free is what makes a cheap bucket acceptable.

## `bootstrap/`

Local state, then `terraform init -migrate-state` into the bucket it creates. Not in CI.

- `aws_s3_bucket.tfstate` — versioning, SSE-S3, public access blocked, TLS-only bucket
  policy, `prevent_destroy`, `force_destroy = false`.
- `aws_iam_openid_connect_provider.github` — import if it already exists in the account.
- `aws_iam_role.tf_plan` — read-only on the state prefix (`-lock=false` avoids needing
  write).
- `aws_iam_role.tf_apply` — read/write on the state prefix, including `DeleteObject`
  for `*.tflock`.

Both roles pin `sub` to `repo:kevindurb/infra:ref:refs/heads/main`, never the wildcard,
because the repo is public. The apply role also sits behind the `production` environment
with required reviewers.

## `tailnet/`

```hcl
backend "s3" {
  bucket       = "kevindurb-tfstate"
  key          = "tailnet/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
```

Managed:

- `tailscale_acl` — `policy.hujson`, moved verbatim from `k8s`.
- `tailscale_tailnet_settings` — `acls_externally_managed_on`, `acls_external_link`,
  `https_enabled`, `devices_key_duration_days`, `devices_auto_updates_on`,
  `devices_approval_on`.
- `tailscale_dns_configuration` — `magic_dns = false`, split DNS for
  `*.beaver-cloud.ts.net` → `100.100.100.100` (matching what the router's dnsmasq already
  forwards), `override_local_dns = false`, search paths.
- `tailscale_service` — the hand-created Services only: `svc:travel-tv`,
  `svc:travel-moonlight`, `svc:travel-jellyfin`. The operator publishes its own
  Services (`svc:argocd` and friends) through VIPService CRs; leave those alone.

## Rollout order

1. `bootstrap/` locally; migrate its state into the bucket; create the Tailscale
   federated identity; set `AWS_*` repository variables and the `production` environment.
2. Add `tailnet/` with everything **imported**: settings → DNS → services → ACL, running
   `plan` until it is empty. Do not arm apply-on-main before this is clean.
3. Same change window, in `kevindurb/k8s`: delete `tailscale/policy.hujson` and
   `.github/workflows/tailscale.yml`, and repoint `AGENTS.md:85`,
   `docs/pr-agent.md:11,24`, `docs/tsidp-to-pocket-id.md:70`. Two writers on one policy
   file is the one thing that must not overlap.
4. Split `docs/tailscale-acl-hardening.md` in `k8s`: the living target model (groups,
   tags, grants, appendix) belongs here; the dated findings and rollout history stay in
   `k8s`.
5. Arm apply-on-main.
6. **Last**, set `acls_externally_managed_on = true`, so the console editor remains
   break-glass until everything has applied cleanly.

## Verification

- `terraform plan` empty on a fresh clone with the plan role.
- A no-op PR merges without an apply that changes anything.
- `tailscale status` on a client shows the same tags and groups as before.
- `https://argocd.beaver-cloud.ts.net` still serves and gatus stays green.
- A deliberately wrong tag in `policy.hujson` fails the PR at plan time (the `tests`
  section).

## Rollback

`git revert` on `policy.hujson` plus a re-apply restores the previous policy. The console
editor stays usable until step 6. `old-k8s-infra` keeps the pre-move history.

## Deferred

- **Device tags.** `dev` (`tag:dev`), `ai`, `bastion`, `router`, `travel-router`,
  `travel-lab`, `golink`, `work`, `personal`, `border0-managed` are all tagged out of band
  (console, or `--advertise-tags` at join). `tailscale_device_tags` would need the
  `devices:core` scope, which also permits deleting and authorizing machines, and it
  addresses devices by node ID, so a re-registered device churns the plan. Left manual;
  revisit only if a tag actually goes missing.
- **Tag-vocabulary drift check in `k8s`.** 34 manifests carry `tailscale.com/tags`
  annotations and the policy references `svc:` names; a tag missing from `tagOwners` or
  `autoApprovers.services` fails as a 400 and the Ingress silently never serves. The
  nightly plan cannot see the cluster's manifests, so catching that needs a separate
  check in `k8s`.
- **Nightly drift plan.** `terraform plan -detailed-exitcode` on a schedule, opening an
  issue on exit code 2. Straightforward to add once the state backend exists.
