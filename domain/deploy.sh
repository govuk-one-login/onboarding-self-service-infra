#!/usr/bin/env bash
# Apply infrastructure config to an AWS account
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."
set -eu -o pipefail

ENVIRONMENT="${1}"
STACK_NAME="domain-config"


  PERMITTED_ENVIRONMENTS="dev development build staging integration production"
  if ! [[ ${PERMITTED_ENVIRONMENTS} =~ ( |^)${ENVIRONMENT}( |$) ]]; then
    echo "Environment provided: ${ENVIRONMENT} is not one of ${PERMITTED_ENVIRONMENTS}"
    exit 1
  fi

case "$ENVIRONMENT" in
  "dev"| "development")
    ACCOUNT="di-onboarding-development"
      ;;
  "build")
    ACCOUNT="di-onboarding-build"
      ;;
  "staging")
    ACCOUNT="di-onboarding-staging"
      ;;
  "integration")
    ACCOUNT="di-onboarding-integration"
      ;;
  "production")
    ACCOUNT="di-onboarding-production"
      ;;
    *)
    exit 1
        ;;
esac

function deploy {

  echo "Deploying the domain configuration to $ENVIRONMENT"

  ${ROOT_DIR}/scripts/deploy-sam-stack.sh "${@:2}" \
    --validate \
    --stack-name "$STACK_NAME" \
    --template "${BASE_DIR}/domain.template.yml"
}

PARAMS=();
PARAMS_FILE="$(pwd)/config/${ENVIRONMENT}/parameters.json"
mapfile -t PARAMS < <(jq -r '.[] | to_entries[] | "\(.key)=\(.value)"' ${PARAMS_FILE})

TAGS_FILE="$(pwd)/config/tags.json"
TAGS=();
mapfile -t TAGS < <(jq -r '. | to_entries[] | "\(.key)=\(.value)"' ${TAGS_FILE})

deploy "$ACCOUNT" ${PARAMS:+--parameters ${PARAMS[@]}} ${TAGS:+--tags ${TAGS[@]}} "${@:2}"
