#!/usr/bin/env bash
# Set up Parameter Store parameters and Secrets Manager secrets required to deploy Admin Tool stacks
cd "$(dirname "${BASH_SOURCE[0]}")"
set -eu

ACCOUNT=$(../scripts/aws.sh get-current-account-name)
PARAMETER_NAME_PREFIX=/product-pages
MANUAL_PARAMETERS=(google_analytics_gtm_container_id universal_analytics_gtm_container_id)
MANUAL_SECRETS=(zendesk_api_token zendesk_group_id zendesk_username register_spreadsheet_id vcap_services servicenow_auth_credentials servicenow_url jira_api_key)

declare -A PARAMETERS=(
  [enable_google_sheets]=$PARAMETER_NAME_PREFIX/frontend/google-sheets-integration-enabled
  [use_stub_sheets]=$PARAMETER_NAME_PREFIX/frontend/use-stub-sheets
  [register_sheet_data_range]=$PARAMETER_NAME_PREFIX/frontend/register-sheet-data-range
  [register_sheet_header_range]=$PARAMETER_NAME_PREFIX/frontend/register-sheet-header-range
  [mailing_list_sheet_data_range]=$PARAMETER_NAME_PREFIX/frontend/mailing-list-sheet-data-range
  [mailing_list_sheet_header_range]=$PARAMETER_NAME_PREFIX/frontend/mailing-list-sheet-header-range
  [prototype_access_sheet_data_range]=$PARAMETER_NAME_PREFIX/frontend/prototype-access-sheet-data-range
  [prototype_access_sheet_header_range]=$PARAMETER_NAME_PREFIX/frontend/prototype-access-sheet-header-range
  [zendesk_api_url]=$PARAMETER_NAME_PREFIX/frontend/zendesk-api-url
  [zendesk_tag]=$PARAMETER_NAME_PREFIX/frontend/zendesk-tag
  [zendesk_tag_one_login_admin_tool]=$PARAMETER_NAME_PREFIX/frontend/zendesk-tag-one-login-admin-tool
  [test_banner]=$PARAMETER_NAME_PREFIX/frontend/show-test-banner
  [use_stub_zendesk]=$PARAMETER_NAME_PREFIX/frontend/use-stub-zendesk
  [google_tag_id]=$PARAMETER_NAME_PREFIX/frontend/google-tag-id
  [google_analytics_gtm_container_id]=$PARAMETER_NAME_PREFIX/frontend/google-analytics-4-gtm-container-id
  [universal_analytics_gtm_container_id]=$PARAMETER_NAME_PREFIX/frontend/universal-analytics-gtm-container-id
  [google_analytics_disabled]=$PARAMETER_NAME_PREFIX/frontend/google-analytics-4-disabled
  [universal_analytics_disabled]=$PARAMETER_NAME_PREFIX/frontend/universal-analytics-disabled
  [admin_tool_url]=$PARAMETER_NAME_PREFIX/frontend/admin-tool-url
  [show_test_banner]=$PARAMETER_NAME_PREFIX/frontend/show-test-banner
  [use_stub_servicenow]=$PARAMETER_NAME_PREFIX/frontend/use-stub-servicenow
  # jira
  [enable_jira_integration]=$PARAMETER_NAME_PREFIX/frontend/jira-integration-enabled
  [jira_user_name]=$PARAMETER_NAME_PREFIX/frontend/jira-auth-user-name
  [use_stub_jira]=$PARAMETER_NAME_PREFIX/frontend/use-stub-jira

)

declare -A SECRETS=(
  # zendesk
  [zendesk_api_token]=$PARAMETER_NAME_PREFIX/frontend/zendesk-api-token
  [zendesk_group_id]=$PARAMETER_NAME_PREFIX/frontend/zendesk-group-id
  [zendesk_username]=$PARAMETER_NAME_PREFIX/frontend/zendesk-username
  # spreadsheet
  [register_spreadsheet_id]=$PARAMETER_NAME_PREFIX/frontend/register-spreadsheet-id
  [mailing_list_spreadsheet_id]=$PARAMETER_NAME_PREFIX/frontend/mailing-list-spreadsheet-id
  #  vcap
  [vcap_services]=$PARAMETER_NAME_PREFIX/frontend/vcap-services
  # servicenow
  [servicenow_auth_credentials]=$PARAMETER_NAME_PREFIX/frontend/servicenow-auth-credentials
  [servicenow_url]=$PARAMETER_NAME_PREFIX/frontend/servicenow-url
  [jira_api_key]=$PARAMETER_NAME_PREFIX/frontend/jira-auth-credentials
)

# ============================
# Product Pages parameters
# this will only create new params if not exists
# and will not update any existing params
# ============================
function check-frontend-params {
  local parameter=${PARAMETERS[test_banner]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "true"

  parameter=${PARAMETERS[show_test_banner]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "$([[ $ACCOUNT == production ]] && echo false || echo true)"

  parameter=${PARAMETERS[admin_tool_url]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "https://admin.sign-in.service.gov.uk"
}

function check-google-sheet-params {
  local parameter=${PARAMETERS[enable_google_sheets]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "true"

  parameter=${PARAMETERS[use_stub_sheets]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "false"

  parameter=${PARAMETERS[register_sheet_data_range]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "Getstarted!A1"

  parameter=${PARAMETERS[register_sheet_header_range]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "Getstarted!A1:Y1"

  parameter=${PARAMETERS[mailing_list_sheet_data_range]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "'user who have requested to join the mailing list '!A1"

  parameter=${PARAMETERS[mailing_list_sheet_header_range]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "'user who have requested to join the mailing list '!A1:D1"

  parameter=${PARAMETERS[prototype_access_sheet_data_range]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "Htmlprototypeaccess!A1"

  parameter=${PARAMETERS[prototype_access_sheet_header_range]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "Htmlprototypeaccess!A1:Y1"
}

function check-google-analytics-params {
  local parameter=${PARAMETERS[google_tag_id]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "GTM-PFTQ6G2"

  parameter=${PARAMETERS[universal_analytics_disabled]}
  check-parameter-set "$parameter" || write-parameter-value "$parameter" "false"

  parameter=${PARAMETERS[google_analytics_disabled]}
  check-parameter-set "$parameter" ||
    write-parameter-value "$parameter" "$([[ $ACCOUNT == production ]] && echo true || echo false)"
}

function check-zendesk-params {
  local parameter=${PARAMETERS[use_stub_zendesk]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "true"

  parameter=${PARAMETERS[zendesk_api_url]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "https://govuk.zendesk.com/api/v2"

  parameter=${PARAMETERS[zendesk_tag]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "sign_in_service_teams"

  parameter=${PARAMETERS[zendesk_tag_one_login_admin_tool]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "self_service_admin"
}

function check-servicenow-params {
  local parameter=${PARAMETERS[use_stub_servicenow]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "false"
}

function check-jira-params {
  local parameter=${PARAMETERS[enable_jira_integration]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "false"

  parameter=${PARAMETERS[use_stub_jira]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "false"

  parameter=${PARAMETERS[jira_user_name]}
  check-parameter-set "${parameter}" || write-parameter-value "$parameter" "atlassian-service-account-jira-integration@digital.cabinet-office.gov.uk"
}

# ============================

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
  aws secretsmanager create-secret --kms-key-id "$(get-secret-key)" --name "$1" --secret-string "$(xargs <<< "$2")" > /dev/null
}

function get-secret-key {
  echo "alias${PARAMETER_NAME_PREFIX}/${ACCOUNT}-secrets-key"
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
  echo "--- check-manual-secrets ---"
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
  ../scripts/aws.sh check-current-account

  # set secrets
  check-manual-secrets

  # set manual parameters
  check-manual-parameters

  # set default parameters
  check-frontend-params
  check-google-sheet-params
  check-google-analytics-params
  check-zendesk-params
  check-servicenow-params
  check-jira-params

  # Display
  print-parameters
  print-secrets
}

[[ "$*" ]] || check-deployment-parameters
[[ "$*" ]] && "$@"
