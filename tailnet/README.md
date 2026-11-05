# tailnet

Owns the Tailscale control plane: the policy file (`policy.hujson`), tailnet settings,
DNS configuration, and the Services that were created by hand in the admin console.

State key: `tailnet/terraform.tfstate` in the `kevindurb-tfstate` bucket. The backend
block is added once `bootstrap/` has created the bucket.

## Not managed here

- **Anything with a credential in it.** `tailscale_oauth_client`, `tailscale_tailnet_key`
  and `tailscale_webhook` all put secrets into state. OAuth clients stay in the console;
  the provider authenticates with a federated identity instead, so there is no secret to
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
  oauth_client_id = "<federated identity client id>"   # not a secret
  audience        = "<audience configured on the identity>"
  tailnet         = "-"
}
```

The workflow supplies the OIDC token via `permissions: id-token: write`. Note that
`scopes` is ignored in federated mode — a read-only identity is a second credential, not
a flag.
