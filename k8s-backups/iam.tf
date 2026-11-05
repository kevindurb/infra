data "aws_iam_policy_document" "restic_boundary" {
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

# The boundary is deliberately a separate document from the user policy. It is
# the ceiling on the identity, so changing the user's inline policy must not
# silently widen it.
resource "aws_iam_policy" "restic_boundary" {
  name        = var.restic_boundary_name
  path        = var.terraform_path
  description = "Caps the VolSync restic user at the volsync/ prefix of the Kubernetes backup bucket."
  policy      = data.aws_iam_policy_document.restic_boundary.json

  tags = {
    Name = var.restic_boundary_name
  }
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
  path                 = var.terraform_path
  permissions_boundary = aws_iam_policy.restic_boundary.arn

  tags = {
    Name = var.restic_user_name
  }
}

resource "aws_iam_user_policy" "restic" {
  name   = "volsync-restic"
  user   = aws_iam_user.restic.name
  policy = data.aws_iam_policy_document.restic.json
}
