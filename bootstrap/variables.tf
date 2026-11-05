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

variable "github_oidc_subject" {
  description = <<-EOT
    Exact token.actions.githubusercontent.com:sub allowed to assume the CI roles.

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
