variable "aws_region" {
  description = "Region for the backup bucket and the SSM parameter."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = <<-EOT
    S3 bucket that holds Kubernetes backups. Restic/VolSync data lives under
    the volsync/ prefix so other backup types can share the bucket later.

    Must start with the terraform_s3_bucket_prefix used in bootstrap/ (default
    kevindurb-infra-), so the shared CI role can manage it.
  EOT
  type        = string
  default     = "kevindurb-infra-k8s-backups"
}

variable "terraform_path" {
  description = <<-EOT
    IAM path shared by Terraform-managed identities. Must match the convention
    in bootstrap/ so the CI role can manage this user and its policy.
  EOT
  type        = string
  default     = "/infra/"

  validation {
    condition     = can(regex("^/.+/$", var.terraform_path))
    error_message = "terraform_path must start and end with /."
  }
}

variable "restic_user_name" {
  description = <<-EOT
    IAM user used by the VolSync restic movers. It lives under the /infra/
    path so the shared CI roles can manage it.
  EOT
  type        = string
  default     = "k8s-backups-restic"
}

variable "restic_boundary_name" {
  description = <<-EOT
    Permissions boundary attached to the restic user. It lives in this root
    under the /infra/ policy path, together with the rest of the identity.
  EOT
  type        = string
  default     = "k8s-backups-restic-boundary"
}

variable "restic_ssm_parameter_name" {
  description = <<-EOT
    SSM SecureString that holds the restic user's access key. The parameter is
    created by scripts/ensure-restic-key.sh, not by Terraform, so the secret
    never enters state.
  EOT
  type        = string
  default     = "/infra/k8s-backups/volsync/restic/s3-access-key"
}

variable "restic_key_version" {
  description = <<-EOT
    Bump this to create a new access key and write it to SSM. The script leaves
    the old key in place so backups keep working until the Kubernetes secrets
    have been resealed; delete the old key by hand afterwards.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.restic_key_version >= 1
    error_message = "restic_key_version must be at least 1."
  }
}
