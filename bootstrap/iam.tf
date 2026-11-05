locals {
  # Exact-match subject: a wildcard here would let any branch, tag or pull
  # request in this public repo assume the roles.
  github_subject = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # thumbprint_list is omitted: GitHub's certificate chains to a root CA that
  # AWS trusts, so no thumbprint is needed. Leaving it out also keeps an
  # imported provider from showing a permanent diff against the stored value.

  tags = {
    Name = "github-actions"
  }
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }
  }
}

resource "aws_iam_role" "tf_plan" {
  name                 = "tf_plan"
  description          = "Read-only on the Terraform state bucket; assumed by plan jobs via GitHub OIDC."
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "tf_plan" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }

  statement {
    sid       = "ReadStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/*"]
  }
}

resource "aws_iam_role_policy" "tf_plan" {
  name   = "tf_plan"
  role   = aws_iam_role.tf_plan.id
  policy = data.aws_iam_policy_document.tf_plan.json
}

resource "aws_iam_role" "tf_apply" {
  name                 = "tf_apply"
  description          = "Read/write on the Terraform state bucket; assumed by apply jobs via GitHub OIDC."
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "tf_apply" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }

  statement {
    sid    = "ReadWriteStateObjects"
    effect = "Allow"

    # DeleteObject is for the *.tflock lock object that use_lockfile creates.
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = ["${aws_s3_bucket.tfstate.arn}/*"]
  }
}

resource "aws_iam_role_policy" "tf_apply" {
  name   = "tf_apply"
  role   = aws_iam_role.tf_apply.id
  policy = data.aws_iam_policy_document.tf_apply.json
}
