terraform {
  backend "s3" {
    bucket       = "kevindurb-tfstate"
    key          = "tailnet/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
