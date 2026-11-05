provider "tailscale" {
  # Federated identity, not a stored secret. GitHub Actions supplies
  # TAILSCALE_OAUTH_CLIENT_ID and TAILSCALE_AUDIENCE, and the provider discovers
  # the workflow's OIDC token itself. For a local plan, set TAILSCALE_API_KEY,
  # or set TAILSCALE_IDENTITY_TOKEN alongside the client ID and audience.
  tailnet = "-"
}
