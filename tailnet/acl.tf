resource "tailscale_acl" "this" {
  # Copied verbatim from kevindurb/k8s. The provider preserves HuJSON comments
  # and compares the canonical HuJSON, so whitespace is not a diff.
  acl = file("${path.module}/policy.hujson")

  # reset_acl_on_destroy defaults to false, so destroying this root leaves the
  # tailnet policy in place. Do not set it explicitly: on import that adds a
  # one-attribute diff to an otherwise clean adoption.

  # overwrite_existing_content is deliberately not set. The import in
  # imports.tf adopts the existing policy; leaving this false prevents a
  # non-default policy from being overwritten by accident.
}
