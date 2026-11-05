# Adopt the existing tailnet policy on the first apply. Import blocks are
# no-ops once the resource is in state; keeping this means a rebuilt state
# re-adopts the live policy instead of trying to create a duplicate.
#
# The singleton resource accepts an arbitrary import ID. This root currently
# manages only the policy file.

import {
  to = tailscale_acl.this
  id = "acl"
}
