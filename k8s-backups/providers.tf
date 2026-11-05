provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "infra"
      Component = "k8s-backups"
      ManagedBy = "terraform"
    }
  }
}
