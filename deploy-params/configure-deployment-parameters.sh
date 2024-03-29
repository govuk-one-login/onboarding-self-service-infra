#!/usr/bin/env bash
# Set up Parameter Store parameters and Secrets Manager secrets required to deploy Admin Tool stacks
cd "$(dirname "${BASH_SOURCE[0]}")"
set -eu

ACCOUNT=$(../aws.sh get-current-account-name)
PARAMETER_NAME_PREFIX=/self-service
MANUAL_PARAMETERS=(auth_base_url api_notification_email google_tag_id google_analytics_gtm_container_id universal_analytics_gtm_container_id)
MANUAL_SECRETS=(auth_api_key notify_api_key)

declare -A PARAMETERS=(
  [test_banner]=$PARAMETER_NAME_PREFIX/frontend/show-test-banner
  [google_tag_id]=$PARAMETER_NAME_PREFIX/frontend/google-tag-id
  [google_analytics_gtm_container_id]=$PARAMETER_NAME_PREFIX/frontend/google-analytics-4-gtm-container-id
  [universal_analytics_gtm_container_id]=$PARAMETER_NAME_PREFIX/frontend/universal-analytics-gtm-container-id
  [google_analytics_disabled]=$PARAMETER_NAME_PREFIX/frontend/google-analytics-4-disabled
  [universal_analytics_disabled]=$PARAMETER_NAME_PREFIX/frontend/universal-analytics-disabled
  [cognito_external_id]=$PARAMETER_NAME_PREFIX/cognito/external-id
  [deletion_protection]=$PARAMETER_NAME_PREFIX/config/deletion-protection-enabled
  [api_notification_email]=$PARAMETER_NAME_PREFIX/api/notifications-email
  [allowed_email_domains_source]=$PARAMETER_NAME_PREFIX/frontend/allowed-email-domains-source
  [user_signup_sheet_data_range]=$PARAMETER_NAME_PREFIX/frontend/user-signup-sheet-data-range
  [user_signup_sheet_header_range]=$PARAMETER_NAME_PREFIX/frontend/user-signup-sheet-header-range
  [public_beta_sheet_data_range]=$PARAMETER_NAME_PREFIX/frontend/public-beta-sheet-data-range
  [public_beta_sheet_header_range]=$PARAMETER_NAME_PREFIX/frontend/public-beta-sheet-header-range
  [use_cognito_dr]=$PARAMETER_NAME_PREFIX/frontend/use-cognito-dr
  [use_stub_otp]=$PARAMETER_NAME_PREFIX/frontend/use-stub-otp
  [identity_verification_enabled]=$PARAMETER_NAME_PREFIX/api/identity-verification-enabled
  [auth_base_url]=$PARAMETER_NAME_PREFIX/api/auth-base-url
)

declare -A SECRETS=(
  [auth_api_key]=$PARAMETER_NAME_PREFIX/api/client-registry-api-key
  [notify_api_key]=$PARAMETER_NAME_PREFIX/cognito/notify-api-key
  [session_secret]=$PARAMETER_NAME_PREFIX/frontend/session-secret
  [google_sheet_credentials]=$PARAMETER_NAME_PREFIX/frontend/google-sheet-credentials
  [user_signup_sheet_id]=$PARAMETER_NAME_PREFIX/frontend/user-signup-sheet-id
  [fixed_otp_credentials]=$PARAMETER_NAME_PREFIX/frontend/fixed-otp-credentials
)

function set-paramswith-values {
  local parameter=${PARAMETERS[public_beta_sheet_data_range]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "Publicbeta!A1"

  local parameter=${PARAMETERS[public_beta_sheet_header_range]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "Publicbeta!A1:Y1"

  local parameter=${PARAMETERS[identity_verification_enabled]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "Yes"
}

function check-parameter-set {
  [[ $(xargs < <(get-parameter-value "$1")) ]]
}

function check-secret-set {
  aws secretsmanager describe-secret --secret-id "$1" &> /dev/null
}

function get-parameter-value {
  aws ssm get-parameter --name "$1" --query "Parameter.Value" --output text 2> /dev/null
}

function write-parameter-value {
  echo "Setting '$1' to '$2'"
  aws ssm put-parameter --name "$1" --value "$(xargs <<< "$2")" --type String --overwrite > /dev/null
}

function write-secret-value {
  echo "Setting secret '$1'"
  aws secretsmanager create-secret --name "$1" --secret-string "$(xargs <<< "$2")" > /dev/null
}

function get-value-from-user {
  local name=$1 type=${2:-parameter} value
  while [[ -z $(xargs <<< "${value:-}") ]]; do read -rp "Enter a value for the $type '$name': " value; done
  echo "$value"
}

function check-manual-parameters {
  local parameter
  for parameter in "${MANUAL_PARAMETERS[@]}"; do check-parameter "${PARAMETERS[$parameter]}"; done
}

function check-manual-secrets {
  local secret
  for secret in "${MANUAL_SECRETS[@]}"; do check-secret "${SECRETS[$secret]}"; done
}

function check-parameter {
  local parameter=$1
  check-parameter-set "$parameter" || write-parameter-value "$parameter" "$(get-value-from-user "$parameter")"
}

function check-secret {
  local secret=$1
  check-secret-set "$secret" || write-secret-value "$secret" "$(get-value-from-user "$secret" secret)"
}

function check-session-secret {
  local secret=${SECRETS[session_secret]}
  check-secret-set "$secret" || write-secret-value "$secret" "$(uuidgen)"
}

function check-google-sheet-credentials {
  local secret=${SECRETS[google_sheet_credentials]}
  check-secret-set "$secret" || write-secret-value "$secret" "$(uuidgen)"
}

function check-fixed-otp-credentials {
  local secret=${SECRETS[fixed_otp_credentials]}
  check-secret-set "$secret" || write-secret-value "$secret" "[{}]"
}

function check-user-signup-sheet-id {
  local secret=${SECRETS[user_signup_sheet_id]}
  check-secret-set "$secret" || write-secret-value "$secret" "$(uuidgen)"
}

function check-google-analytics-disabled {
  local parameter=${PARAMETERS[google_analytics_disabled]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "$([[ $ACCOUNT == production ]] && echo true || echo false)"
}
function check-universal-analytics-disabled {
  local parameter=${PARAMETERS[universal_analytics_disabled]}
  check-parameter-set "$parameter" || write-parameter-value "$parameter" "false"
}

function check-cognito-dr {
  local parameter=${PARAMETERS[use_cognito_dr]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "false"
}

function check-stub-otp {
  local parameter=${PARAMETERS[use_stub_otp]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "false"
}

function check-cognito-external-id {
  local parameter=${PARAMETERS[cognito_external_id]}
  check-parameter-set "$parameter" || write-parameter-value "$parameter" "$(uuidgen)"
}

function check-deletion-protection {
  local parameter=${PARAMETERS[deletion_protection]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "$([[ $ACCOUNT == production ]] && echo ACTIVE || echo INACTIVE)"
}

function check-test-banner {
  local parameter=${PARAMETERS[test_banner]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "$([[ $ACCOUNT == production ]] && echo false || echo true)"
}

function check-allowed-email-domains-source {
  local parameter=${PARAMETERS[allowed_email_domains_source]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "$([[ $ACCOUNT == production ]] && echo 'allowed-email-domains' || echo 'allowed-test-domains')"
}

function print-parameters {
  local parameter
  echo "--- Deployment parameters ---"
  for parameter in "${PARAMETERS[@]}"; do
    echo "$parameter: $(get-parameter-value "$parameter")"
  done
}

function print-secrets {
  local secret
  echo "--- Secrets ---"
  for secret in "${SECRETS[@]}"; do
    check-secret-set "$secret" && echo "$secret"
  done
}

function check-deployment-parameters {
  ../aws.sh check-current-account

  check-test-banner
  check-cognito-dr
  check-stub-otp
  check-cognito-external-id
  check-deletion-protection
  check-google-analytics-disabled
  check-universal-analytics-disabled
  check-manual-parameters

  check-session-secret
  check-google-sheet-credentials
  check-user-signup-sheet-id
  check-manual-secrets

  check-allowed-email-domains-source

  set-paramswith-values

  print-parameters
  print-secrets
}

[[ "$*" ]] || check-deployment-parameters
[[ "$*" ]] && "$@"
