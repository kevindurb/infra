output "state_bucket" {
  description = "Bucket holding every root module's state."
  value       = aws_s3_bucket.tfstate.bucket
}

output "tf_plan_role_arn" {
  description = "Role for read-only plan jobs; set as the AWS_PLAN_ROLE_ARN repository variable."
  value       = aws_iam_role.tf_plan.arn
}

output "tf_apply_role_arn" {
  description = "Role for apply jobs; set as the AWS_APPLY_ROLE_ARN repository variable."
  value       = aws_iam_role.tf_apply.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.github.arn
}
