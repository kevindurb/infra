data "aws_caller_identity" "current" {}

locals {
  # The boundary is created in bootstrap/ so the CI role can manage the user's
  # inline policy but cannot change the ceiling on what that user can do.
  restic_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.restic_boundary_name}"
}

data "aws_iam_policy_document" "restic" {
  statement {
    sid    = "ListVolsyncPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [aws_s3_bucket.k8s_backups.arn]

    # HeadBucket sends no s3:prefix, so IfExists lets restic's bucket-existence
    # check through while still refusing listings of other backup prefixes.
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
    resources = [aws_s3_bucket.k8s_backups.arn]
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

    resources = ["${aws_s3_bucket.k8s_backups.arn}/volsync/*"]
  }
}

resource "aws_iam_user" "restic" {
  name                 = var.restic_user_name
  permissions_boundary = local.restic_boundary_arn

  tags = {
    Name = var.restic_user_name
  }
}

resource "aws_iam_user_policy" "restic" {
  name   = "volsync-restic"
  user   = aws_iam_user.restic.name
  policy = data.aws_iam_policy_document.restic.json
}
