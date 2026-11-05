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

variable "terraform_iam_user_path" {
  description = <<-EOT
    IAM path for users managed by Terraform roots. The plan/apply roles are
    scoped to this path so bootstrap does not need to know about individual
    roots. Must start and end with /.
  EOT
  type        = string
  default     = "/infra/"

  validation {
    condition     = can(regex("^/.+/$", var.terraform_iam_user_path))
    error_message = "terraform_iam_user_path must start and end with /."
  }
}

variable "terraform_iam_policy_path" {
  description = <<-EOT
    IAM path for policies managed by Terraform roots. Must start and end with /.
  EOT
  type        = string
  default     = "/infra/"

  validation {
    condition     = can(regex("^/.+/$", var.terraform_iam_policy_path))
    error_message = "terraform_iam_policy_path must start and end with /."
  }
}

variable "terraform_s3_bucket_prefix" {
  description = <<-EOT
    Name prefix for S3 buckets managed by Terraform roots. The apply role can
    manage bucket settings for these buckets but has no object-level access.
  EOT
  type        = string
  default     = "kevindurb-infra-"
}

variable "terraform_ssm_parameter_path" {
  description = <<-EOT
    SSM parameter path for values managed by Terraform roots. Must start with /.
  EOT
  type        = string
  default     = "/infra/"

  validation {
    condition     = can(regex("^/.*$", var.terraform_ssm_parameter_path))
    error_message = "terraform_ssm_parameter_path must start with /."
  }
}

variable "github_oidc_subject" {
  description = <<-EOT
    Exact token.actions.githubusercontent.com:sub for a push to main.

    Repositories created after 2026-07-15 always use GitHub's immutable subject
    format, which embeds the owner and repository IDs:
    repo:OWNER@OWNER-ID/REPO@REPO-ID:ref:refs/heads/BRANCH
    For this repo that is kevindurb@2565006/infra@1446549993. The IDs are public
    and make the claim resistant to renames and namespace recycling. Do not
    replace them with a wildcard.
  EOT
  type        = string
  default     = "repo:kevindurb@2565006/infra@1446549993:ref:refs/heads/main"

  validation {
    condition     = !can(regex("[*?]", var.github_oidc_subject))
    error_message = "The OIDC subject must be an exact match; wildcards are not allowed in this public repository."
  }
}

variable "github_oidc_pull_request_subject" {
  description = <<-EOT
    Exact token.actions.githubusercontent.com:sub for pull requests opened from a
    branch in this repository. The workflow skips fork PRs, so they never request
    a token. Only the read-only tf_plan role trusts this subject.
  EOT
  type        = string
  default     = "repo:kevindurb@2565006/infra@1446549993:pull_request"

  validation {
    condition     = !can(regex("[*?]", var.github_oidc_pull_request_subject))
    error_message = "The OIDC subject must be an exact match; wildcards are not allowed in this public repository."
  }
}

variable "github_oidc_environment_subject" {
  description = <<-EOT
    Exact token.actions.githubusercontent.com:sub for the apply job, which declares
    `environment: production`. Jobs that target an environment get an
    environment-qualified subject instead of a ref-qualified one, so this is the value
    tf_apply actually presents. Branch restriction comes from the environment's
    deployment branch policy (main only) plus its required reviewers.
  EOT
  type        = string
  default     = "repo:kevindurb@2565006/infra@1446549993:environment:production"

  validation {
    condition     = !can(regex("[*?]", var.github_oidc_environment_subject))
    error_message = "The OIDC subject must be an exact match; wildcards are not allowed in this public repository."
  }
}
