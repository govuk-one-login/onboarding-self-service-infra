#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."
set -eu

STACK_NAME=secure-pipelines-support

ACCOUNT=$(${ROOT_DIR}/scripts/aws.sh get-current-account-name)

function deploy {
  local is_initial_account=$(${ROOT_DIR}/scripts/aws.sh is-initial-account "$ACCOUNT")
  local downstream_accounts=$(${ROOT_DIR}/scripts/aws.sh get-all-downstream-accounts "$ACCOUNT" string)

  ${ROOT_DIR}/scripts/deploy-sam-stack.sh "$@" \
    --validate \
    --stack-name $STACK_NAME \
    --template deployment-support.template.yml \
    --tags \
        Product="GOV.UK One Login" \
        System="Dev Platform" \
        Service="ci/cd" \
        Owner="Self-Service Team" \
        Environment="$ACCOUNT" \
    --parameters \
        InitialAccount=${is_initial_account:-false} \
        Environment="${ACCOUNT:-}" \
        DownstreamAccounts="${downstream_accounts:-''}"

    update-github
}

function update-github {
  local is_initial_account=$(${ROOT_DIR}/scripts/aws.sh is-initial-account "$ACCOUNT")

  [[ $is_initial_account == true ]] || return

  ${ROOT_DIR}/configure-github-repo.sh update-deployment-environment "$ACCOUNT"-secure-pipelines $STACK_NAME \
      SigningProfileName ContainerSigningKeyARN
}

deploy
