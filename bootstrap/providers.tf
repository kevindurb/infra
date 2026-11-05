provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "infra"
      Component = "bootstrap"
      ManagedBy = "terraform"
    }
  }
}
