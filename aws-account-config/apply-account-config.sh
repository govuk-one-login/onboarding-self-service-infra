#!/usr/bin/env bash
# Apply infrastructure config to an AWS account
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."

set -eu -o pipefail

function deploy-config-stack {
  local type=$1

  ${ROOT_DIR}/scripts/deploy-sam-stack.sh "${@:2}" \
    --validate \
    --stack-name "$type"-config \
    --template "$type/$type".template.yml \
    --tags sse:stack-type=config
}

function control-tower {
  deploy-config-stack control-tower --tags sse:stack-role=account-management "$@"
}

function network {
  deploy-config-stack network --tags sse:stack-role=vpc "$@"
}

function logging {
  deploy-config-stack logging --tags sse:stack-role=logging "$@"
}

"$@"
