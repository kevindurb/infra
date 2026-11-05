data "aws_caller_identity" "current" {}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

locals {
  k8s_backups_bucket_arn          = "arn:aws:s3:::${var.k8s_backups_bucket_name}"
  k8s_backups_restic_user_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.k8s_backups_restic_user_name}"
  k8s_backups_restic_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.k8s_backups_restic_boundary_name}"
  k8s_backups_ssm_parameter_arn   = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${trimprefix(var.k8s_backups_ssm_parameter_name, "/")}"
}

# The boundary is the ceiling on the restic user. The k8s-backups root may
# change the user's inline policy, but it cannot raise this ceiling, and the CI
# role cannot change the boundary itself. That keeps a CI role with
# iam:PutUserPolicy from becoming an account-admin escalation path.
data "aws_iam_policy_document" "k8s_backups_restic_boundary" {
  statement {
    sid    = "ListVolsyncPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [local.k8s_backups_bucket_arn]

    # HeadBucket sends no s3:prefix; IfExists lets the bucket-existence check
    # through while still refusing listings of other backup prefixes.
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:prefix"
      values   = ["volsync/*"]
    }
  }

  statement {
    sid       = "ReadBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.k8s_backups_bucket_arn]
  }

  statement {
    sid    = "ManageVolsyncObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = ["${local.k8s_backups_bucket_arn}/volsync/*"]
  }
}

resource "aws_iam_policy" "k8s_backups_restic_boundary" {
  name        = var.k8s_backups_restic_boundary_name
  description = "Caps the VolSync restic user at the volsync/ prefix of the Kubernetes backup bucket."
  policy      = data.aws_iam_policy_document.k8s_backups_restic_boundary.json

  tags = {
    Name = var.k8s_backups_restic_boundary_name
  }
}

# tf_plan can read the bucket and the restic user so it can render a plan. It
# deliberately has no SSM access: the access key is not in state.
data "aws_iam_policy_document" "tf_plan_k8s_backups" {
  statement {
    sid    = "ReadK8sBackupsBucket"
    effect = "Allow"

    actions = [
      "s3:GetBucket*",
      "s3:ListBucket",
      "s3:GetEncryptionConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetReplicationConfiguration",
    ]

    resources = [local.k8s_backups_bucket_arn]
  }

  statement {
    sid    = "ReadK8sBackupsResticUser"
    effect = "Allow"

    actions = [
      "iam:GetUser",
      "iam:GetUserPolicy",
      "iam:ListUserPolicies",
      "iam:ListAccessKeys",
      "iam:ListUserTags",
      "iam:ListAttachedUserPolicies",
    ]

    resources = [local.k8s_backups_restic_user_arn]
  }
}

resource "aws_iam_role_policy" "tf_plan_k8s_backups" {
  name   = "tf_plan_k8s_backups"
  role   = aws_iam_role.tf_plan.id
  policy = data.aws_iam_policy_document.tf_plan_k8s_backups.json
}

# tf_apply can manage the bucket, the restic user and its inline policy, and
# create the access key that the k8s-backups script writes to SSM. It has no
# object-level S3 permissions and no IAM permissions beyond this one user.
data "aws_iam_policy_document" "tf_apply_k8s_backups" {
  statement {
    sid    = "ManageK8sBackupsBucket"
    effect = "Allow"

    actions = [
      "s3:CreateBucket",
      "s3:GetBucket*",
      "s3:ListBucket",
      "s3:GetEncryptionConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetInventoryConfiguration",
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

    resources = [local.k8s_backups_bucket_arn]
  }

  statement {
    sid       = "CreateK8sBackupsResticUser"
    effect    = "Allow"
    actions   = ["iam:CreateUser"]
    resources = [local.k8s_backups_restic_user_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.k8s_backups_restic_boundary_arn]
    }
  }

  statement {
    sid    = "ManageK8sBackupsResticUser"
    effect = "Allow"

    actions = [
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
    ]

    resources = [local.k8s_backups_restic_user_arn]
  }

  statement {
    sid    = "ManageK8sBackupsResticKey"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
    ]

    resources = [local.k8s_backups_ssm_parameter_arn]
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

resource "aws_iam_role_policy" "tf_apply_k8s_backups" {
  name   = "tf_apply_k8s_backups"
  role   = aws_iam_role.tf_apply.id
  policy = data.aws_iam_policy_document.tf_apply_k8s_backups.json
}
