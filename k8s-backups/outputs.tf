locals {
  restic_repository_prefix = "s3:s3.${var.aws_region}.amazonaws.com/${var.bucket_name}/volsync"
}

output "bucket_name" {
  description = "S3 bucket that holds Kubernetes backups."
  value       = aws_s3_bucket.k8s_backups.bucket
}

output "bucket_arn" {
  description = "ARN of the Kubernetes backup bucket."
  value       = aws_s3_bucket.k8s_backups.arn
}

output "region" {
  description = "Region of the backup bucket and the SSM parameter."
  value       = var.aws_region
}

output "restic_repository_prefix" {
  description = "Prefix for per-PVC RESTIC_REPOSITORY values; append /<namespace>/<pvc>."
  value       = local.restic_repository_prefix
}

output "restic_user_name" {
  description = "IAM user used by the VolSync restic movers."
  value       = aws_iam_user.restic.name
}

output "restic_boundary_arn" {
  description = "Permissions boundary attached to the restic user."
  value       = local.restic_boundary_arn
}

output "restic_ssm_parameter_name" {
  description = "SSM SecureString that holds the restic access key."
  value       = var.restic_ssm_parameter_name
}
