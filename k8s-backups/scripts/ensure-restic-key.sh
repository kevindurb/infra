#!/usr/bin/env bash
# Create or rotate the IAM access key used by the VolSync restic movers.
#
# Terraform runs this on apply. The secret goes straight to SSM and is never
# written to Terraform state or printed to the log.

set -euo pipefail

: "${IAM_USER:?IAM_USER is required}"
: "${SSM_PARAM:?SSM_PARAM is required}"
: "${REGION:?REGION is required}"
: "${KEY_VER:?KEY_VER is required}"

export AWS_PAGER=""

if ! [[ "$KEY_VER" =~ ^[1-9][0-9]*$ ]]; then
  echo "error: KEY_VER must be a positive integer, got '$KEY_VER'" >&2
  exit 1
fi

for cmd in aws jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: $cmd is required" >&2
    exit 1
  fi
done

umask 077

key_tmp=""
param_tmp=""
err_tmp=""

cleanup() {
  local f
  for f in "$key_tmp" "$param_tmp" "$err_tmp"; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    if command -v shred >/dev/null 2>&1; then
      shred -u "$f" 2>/dev/null || rm -f "$f"
    else
      rm -f "$f"
    fi
  done
}
trap cleanup EXIT

key_tmp=$(mktemp)
param_tmp=$(mktemp)
err_tmp=$(mktemp)

# Read the current parameter. A missing parameter is expected on the first
# apply; anything else is a real error and must not fall through to creating a
# second key.
existing_json=""
if existing_json=$(aws ssm get-parameter \
  --name "$SSM_PARAM" \
  --with-decryption \
  --query Parameter.Value \
  --output text \
  --region "$REGION" 2>"$err_tmp"); then
  :
else
  if grep -q 'ParameterNotFound' "$err_tmp"; then
    existing_json=""
  else
    cat "$err_tmp" >&2
    exit 1
  fi
fi

existing_version=0
existing_key_id=""
if [ -n "$existing_json" ]; then
  existing_version=$(jq -r '.version // 0' <<<"$existing_json")
  existing_key_id=$(jq -r '.access_key_id // empty' <<<"$existing_json")
fi

existing_status=""
if [ -n "$existing_key_id" ]; then
  existing_status=$(aws iam list-access-keys \
    --user-name "$IAM_USER" \
    --region "$REGION" \
    --query "AccessKeyMetadata[?AccessKeyId=='${existing_key_id}'].Status" \
    --output text)
fi

if [ "$existing_version" -eq "$KEY_VER" ] && [ "$existing_status" = "Active" ]; then
  echo "access key ${existing_key_id} (version ${KEY_VER}) is already in ${SSM_PARAM}"
  exit 0
fi

if [ "$existing_version" -gt "$KEY_VER" ]; then
  echo "error: ${SSM_PARAM} is at version ${existing_version}, newer than requested ${KEY_VER}" >&2
  exit 1
fi

# Inactive keys cannot be used. Remove them so they do not consume AWS's
# two-access-keys-per-user limit.
while IFS= read -r inactive_key; do
  [ -n "$inactive_key" ] || continue
  aws iam delete-access-key \
    --user-name "$IAM_USER" \
    --access-key-id "$inactive_key" \
    --region "$REGION"
done < <(aws iam list-access-keys \
  --user-name "$IAM_USER" \
  --region "$REGION" \
  --query "AccessKeyMetadata[?Status=='Inactive'].AccessKeyId" \
  --output text)

key_count=$(aws iam list-access-keys \
  --user-name "$IAM_USER" \
  --region "$REGION" \
  --query 'length(AccessKeyMetadata)' \
  --output text)

if [ "$key_count" -ge 2 ]; then
  echo "error: ${IAM_USER} already has ${key_count} access keys; delete the old key before rotating" >&2
  aws iam list-access-keys \
    --user-name "$IAM_USER" \
    --region "$REGION" \
    --query 'AccessKeyMetadata[].[AccessKeyId,Status,CreateDate]' \
    --output table >&2
  exit 1
fi

aws iam create-access-key \
  --user-name "$IAM_USER" \
  --region "$REGION" \
  --output json > "$key_tmp"

access_key_id=$(jq -r '.AccessKey.AccessKeyId' "$key_tmp")
secret_access_key=$(jq -r '.AccessKey.SecretAccessKey' "$key_tmp")

if [ -z "$access_key_id" ] || [ "$access_key_id" = "null" ] || \
  [ -z "$secret_access_key" ] || [ "$secret_access_key" = "null" ]; then
  echo "error: aws iam create-access-key did not return a usable key" >&2
  exit 1
fi

# Build a PutParameter CLI input so the secret never appears in argv. The
# Value field is the JSON document the Kubernetes sealing helper parses.
jq -n \
  --arg name "$SSM_PARAM" \
  --arg key_id "$access_key_id" \
  --arg secret "$secret_access_key" \
  --argjson version "$KEY_VER" \
  '{
    Name: $name,
    Type: "SecureString",
    Value: ({access_key_id: $key_id, secret_access_key: $secret, version: $version} | tostring),
    Overwrite: true
  }' > "$param_tmp"

if ! aws ssm put-parameter \
  --cli-input-json "file://${param_tmp}" \
  --region "$REGION" >/dev/null; then
  echo "error: failed to write ${SSM_PARAM}; deleting the new access key ${access_key_id}" >&2
  aws iam delete-access-key \
    --user-name "$IAM_USER" \
    --access-key-id "$access_key_id" \
    --region "$REGION" || true
  exit 1
fi

echo "wrote access key ${access_key_id} (version ${KEY_VER}) to ${SSM_PARAM}"
aws iam list-access-keys \
  --user-name "$IAM_USER" \
  --region "$REGION" \
  --query 'AccessKeyMetadata[].[AccessKeyId,Status,CreateDate]' \
  --output table
