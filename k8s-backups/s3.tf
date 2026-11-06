resource "aws_s3_bucket" "k8s_backups" {
  bucket        = var.bucket_name
  force_destroy = false

  tags = {
    Name = var.bucket_name
  }

  # The bucket holds the only off-site copy of every stateful volume. A
  # Terraform destroy must fail rather than delete it out from under the
  # cluster.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "k8s_backups" {
  bucket = aws_s3_bucket.k8s_backups.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "k8s_backups" {
  bucket = aws_s3_bucket.k8s_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "k8s_backups" {
  bucket = aws_s3_bucket.k8s_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

# Restic's prune deletes pack files. S3 versioning would keep every deleted
# pack as a noncurrent version and inflate the bill, so it is deliberately not
# enabled. Restic's own retention is the version history here.
#
# Object Lock is also deliberately not enabled: it would stop deletion, but it
# would also break restic's prune. Revisit only with a different retention
# design.

resource "aws_s3_bucket_lifecycle_configuration" "k8s_backups" {
  bucket = aws_s3_bucket.k8s_backups.id

  # A mover that dies can leave a multipart upload behind. Restic never
  # resumes it, so expire incomplete uploads instead of paying for them.
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "k8s_backups_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.k8s_backups.arn,
      "${aws_s3_bucket.k8s_backups.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "k8s_backups" {
  bucket = aws_s3_bucket.k8s_backups.id
  policy = data.aws_iam_policy_document.k8s_backups_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.k8s_backups]
}
