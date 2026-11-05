default:
  @just --list

# Root modules. bootstrap is run by hand, once.
roots := "bootstrap tailnet"

# Format and validate every root. No credentials needed.
check:
  #!/usr/bin/env bash
  set -euo pipefail
  terraform fmt -check -recursive
  for root in {{roots}}; do
    ( cd "$root" && terraform init -backend=false -input=false >/dev/null && terraform validate )
  done

# Rewrite formatting in place.
fmt:
  terraform fmt -recursive

# Plan one root, e.g. `just plan tailnet`.
plan root:
  cd {{root}} && terraform init -input=false && terraform plan -input=false

# Apply one root, e.g. `just apply tailnet`.
apply root:
  cd {{root}} && terraform init -input=false && terraform apply -input=false
