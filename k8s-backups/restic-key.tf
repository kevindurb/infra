resource "terraform_data" "restic_key" {
  input = {
    version = var.restic_key_version
  }

  # Re-run when the version is bumped or the script changes. The script is
  # idempotent and exits early when SSM already holds the requested version.
  triggers_replace = [
    tostring(var.restic_key_version),
    filesha256("${path.module}/scripts/ensure-restic-key.sh"),
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/ensure-restic-key.sh"

    environment = {
      IAM_USER  = aws_iam_user.restic.name
      SSM_PARAM = var.restic_ssm_parameter_name
      REGION    = var.aws_region
      KEY_VER   = tostring(var.restic_key_version)
    }
  }

  depends_on = [
    aws_iam_user.restic,
    aws_iam_user_policy.restic,
  ]
}
