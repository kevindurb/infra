variable "aws_region" {
  description = "Region for the state bucket, the OIDC provider and the CI roles."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket that holds every root module's state."
  type        = string
  default     = "kevindurb-tfstate"
}

variable "github_repository" {
  description = "Repository allowed to assume the CI roles, as owner/name."
  type        = string
  default     = "kevindurb/infra"
}

variable "github_branch" {
  description = "Branch whose workflow runs may assume the CI roles. Never a wildcard."
  type        = string
  default     = "main"
}
