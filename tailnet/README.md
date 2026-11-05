# tailnet

Owns the Tailscale policy file (`policy.hujson`) for now. Tailnet settings, DNS, and
Services still live in the admin console; see `../docs/tailnet.md`.

State lives at `s3://kevindurb-tfstate/tailnet/terraform.tfstate`, configured in
`backend.tf`.

## Managed

- `tailscale_acl.this` — `policy.hujson`, copied verbatim from `kevindurb/k8s`.

The root is deliberately limited to the policy file until the import has applied cleanly.
Settings, DNS, and the hand-created Services can move here in later changes.

## Not managed here

- **Tailnet settings, DNS, and Services.** They remain in the admin console. The
  `tailscale_tailnet_settings`, `tailscale_dns_configuration` and `tailscale_service`
  resources can adopt them later without moving the policy again.
- **Anything with a credential in it.** `tailscale_oauth_client`, `tailscale_tailnet_key`
  and `tailscale_webhook` all put secrets into state. OAuth clients stay in the console;
  the provider authenticates with federated identities instead, so there is no secret to
  store at all.
- **The cluster's own tailnet objects.** The operator, ProxyGroups, egress Services and
  the Services it publishes (`svc:argocd` and friends) are owned by Argo CD from
  `kevindurb/k8s`, under `infrastructure/tailscale`. Terraform must not manage them.
- **Device tags.** `dev`, `ai`, `bastion`, `router`, `travel-router`, `travel-lab`,
  `golink`, `work`, `personal` and `border0-managed` are tagged out of band. Bringing
  them under Terraform needs `devices:core`, which also grants delete/authorize on
  machines. Manual for now — see `../docs/tailnet.md`.

## Provider

Federated identity, not a client secret:

```hcl
provider "tailscale" {
  tailnet = "-"
}
```

Credentials come from the environment. In CI the plan job uses a read-only identity and
the apply job a write identity, mirroring `tf_plan` / `tf_apply`:

| Job | Variables |
| --- | --- |
| plan | `TAILSCALE_OAUTH_CLIENT_ID`, `TAILSCALE_AUDIENCE` from the `TAILSCALE_PLAN_*` repository variables |
| apply | the same variables from `TAILSCALE_APPLY_*` |

With only the policy file managed, the plan identity needs `policy_file:read` and the
apply identity needs `policy_file`. The plan-time ACL tests are included in
`policy_file:read`.

For a local plan, set `TAILSCALE_API_KEY`, or set `TAILSCALE_IDENTITY_TOKEN` together with
the client ID and audience. The workflow supplies the OIDC token via
`permissions: id-token: write`.

`scopes` is ignored in federated mode — a read-only identity is a second credential, not
a flag.

## Import

`imports.tf` adopts the existing policy on the first apply. The singleton resource
accepts an arbitrary import ID; the block is a no-op once state exists, so keep it: a
rebuilt state re-adopts the live policy instead of creating a duplicate.

Before merging a change to this root, the plan should show no resource changes after the
import.
