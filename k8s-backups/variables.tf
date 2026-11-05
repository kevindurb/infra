variable "aws_region" {
  description = "Region for the backup bucket and the SSM parameter."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = <<-EOT
    S3 bucket that holds Kubernetes backups. Restic/VolSync data lives under
    the volsync/ prefix so other backup types can share the bucket later.

    Must match var.k8s_backups_bucket_name in bootstrap/, where the restic
    permissions boundary and the CI bucket policy are defined.
  EOT
  type        = string
  default     = "kevindurb-k8s-backups"
}

variable "restic_user_name" {
  description = <<-EOT
    IAM user used by the VolSync restic movers. Must match
    var.k8s_backups_restic_user_name in bootstrap/.
  EOT
  type        = string
  default     = "k8s-backups-restic"
}

variable "restic_boundary_name" {
  description = <<-EOT
    Permissions boundary attached to the restic user. The policy is created in
    bootstrap/ as a security control the CI role cannot change.
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
  default     = "/k8s-backups/volsync/restic/s3-access-key"
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
