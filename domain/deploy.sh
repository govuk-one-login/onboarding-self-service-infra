#!/usr/bin/env bash
# Apply infrastructure config to an AWS account
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."
set -eu -o pipefail

ACCOUNT=$(${ROOT_DIR}/scripts/aws.sh get-current-account-name)
STACK_NAME="domain-config"

function get-servers {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-number "${1:-}")
  local AWS_PROFILE=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$account")

  ${ROOT_DIR}/scripts/aws.sh get-stack-outputs domain-config HostedZoneNameServers
}

function deploy {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-number "${1:-}")
  local AWS_PROFILE=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$account" "admin")

  echo "Deploying the domain configuration to $account"

  ${ROOT_DIR}/scripts/deploy-sam-stack.sh "${@:2}" \
    --validate \
    --stack-name "$STACK_NAME" \
    --template "${BASE_DIR}/domain.template.yml" \
    --tags \
        sse:stack-type=config \
        sse:stack-role=dns
}

if [[ "$ACCOUNT" == production ]]; then
  echo "Getting subdomain name servers..."
  for account in development build staging integration; do
    SERVERS=$(${ROOT_DIR}/scripts/aws.sh get-stack-outputs domain-config HostedZoneNameServers $account) || continue
    PARAMS+=("${account@u}NameServers=$(jq --raw-output ".value" <<< "$SERVERS")")
  done
else
  PARAMS=(Subdomain="$ACCOUNT.")
fi

deploy "$ACCOUNT" ${PARAMS:+--parameters ${PARAMS[@]}} "$@"
