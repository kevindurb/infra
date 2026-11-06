data "aws_caller_identity" "current" {}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

locals {
  terraform_iam_user_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user${var.terraform_iam_user_path}*"
  terraform_iam_policy_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy${var.terraform_iam_policy_path}*"
  terraform_s3_bucket_arn     = "arn:aws:s3:::${var.terraform_s3_bucket_prefix}*"
  terraform_ssm_parameter_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.terraform_ssm_parameter_path}*"
}

# These policies are deliberately root-agnostic. Roots keep their identities
# under /infra/, their buckets under the account prefix, and their parameters
# under /infra/, so bootstrap does not need a new policy for every root.

data "aws_iam_policy_document" "tf_plan_terraform_workers" {
  statement {
    sid    = "ReadTerraformManagedBuckets"
    effect = "Allow"

    actions = [
      "s3:GetBucket*",
      "s3:ListBucket",
      "s3:GetEncryptionConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetReplicationConfiguration",
    ]

    resources = [local.terraform_s3_bucket_arn]
  }

  statement {
    sid    = "ReadTerraformManagedUsers"
    effect = "Allow"

    actions = [
      "iam:GetUser",
      "iam:GetUserPolicy",
      "iam:ListUserPolicies",
      "iam:ListAccessKeys",
      "iam:ListUserTags",
      "iam:ListAttachedUserPolicies",
    ]

    resources = [local.terraform_iam_user_arn]
  }

  statement {
    sid    = "ReadTerraformManagedPolicies"
    effect = "Allow"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListPolicyTags",
      "iam:ListEntitiesForPolicy",
    ]

    resources = [local.terraform_iam_policy_arn]
  }
}

resource "aws_iam_role_policy" "tf_plan_terraform_workers" {
  name   = "tf_plan_terraform_workers"
  role   = aws_iam_role.tf_plan.id
  policy = data.aws_iam_policy_document.tf_plan_terraform_workers.json
}

data "aws_iam_policy_document" "tf_apply_terraform_workers" {
  statement {
    sid    = "ManageTerraformManagedBuckets"
    effect = "Allow"

    actions = [
      "s3:CreateBucket",
      "s3:GetBucket*",
      "s3:ListBucket",
      "s3:GetEncryptionConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketOwnershipControls",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketTagging",
    ]

    resources = [local.terraform_s3_bucket_arn]
    # Bucket settings only. Roots that need object access grant it to their own
    # identities; the CI role must not be able to delete backup data.
  }

  statement {
    sid    = "ManageTerraformManagedUsers"
    effect = "Allow"

    actions = [
      "iam:CreateUser",
      "iam:GetUser",
      "iam:DeleteUser",
      "iam:TagUser",
      "iam:UntagUser",
      "iam:ListUserTags",
      "iam:PutUserPolicy",
      "iam:GetUserPolicy",
      "iam:DeleteUserPolicy",
      "iam:ListUserPolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListAccessKeys",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:UpdateAccessKey",
      "iam:PutUserPermissionsBoundary",
      "iam:DeleteUserPermissionsBoundary",
    ]

    resources = [local.terraform_iam_user_arn]
  }

  statement {
    sid    = "ManageTerraformManagedPolicies"
    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:GetPolicy",
      "iam:DeletePolicy",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:ListPolicyTags",
      "iam:CreatePolicyVersion",
      "iam:GetPolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListEntitiesForPolicy",
    ]

    resources = [local.terraform_iam_policy_arn]
  }

  statement {
    sid    = "ManageTerraformManagedParameters"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
    ]

    resources = [local.terraform_ssm_parameter_arn]
  }

  statement {
    sid    = "UseSsmDefaultKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [data.aws_kms_alias.ssm.target_key_arn]
  }
}

resource "aws_iam_role_policy" "tf_apply_terraform_workers" {
  name   = "tf_apply_terraform_workers"
  role   = aws_iam_role.tf_apply.id
  policy = data.aws_iam_policy_document.tf_apply_terraform_workers.json
}
