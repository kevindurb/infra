# Deliberately no backend block.
#
# bootstrap/ starts on local state: it creates the bucket that every other root
# stores its state in, and the bucket cannot hold the state of the run that
# creates it. After the first local `terraform apply`, add the block below to
# this file and run `terraform init -migrate-state`. See README.md for the exact
# one-time sequence.
#
# terraform {
#   backend "s3" {
#     bucket       = "kevindurb-tfstate"
#     key          = "bootstrap/terraform.tfstate"
#     region       = "us-east-1"
#     encrypt      = true
#     use_lockfile = true
#   }
# }
