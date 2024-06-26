#!/usr/bin/env bash

# Utility script to deploy secrets-key stack
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."

set -e
set -o pipefail

usage() {
  cat << 'EOF'
This script deploys the KMS keys required to create secrets for each application.

Run this script once for each application in each environment.

Usage:
    -e      --environment       The environment to deploy into, should be one of:
                                  - local
                                  - development
                                  - build
                                  - staging
                                  - integration
                                  - production
    -l      --local-name        Used for to distinguish between ephemeral environments (only if --environment is 'local').
    -a      --application       The application to deploy, should be one of:
                                  - self-service
                                  - product-pages
    -h      --help              Prints this help message and exits
EOF
}

while [[ -n ${1:-} ]]; do
  case $1 in
  -e | --environment)
    shift
    ENVIRONMENT=$1
    ;;
  -l | --local-name)
    shift
    LOCAL_NAME=$1
    ;;
  -a | --application)
    shift
    APPLICATION=$1
    ;;
  -y | --no-confirm)
    CONFIRM_CHANGES=false
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo -e "Unknown option $1...\n"
    usage
    exit 1
    ;;
  esac
  shift
done

if [ -z "$ENVIRONMENT" ]; then
  echo "Please specify the environment to deploy to."
  usage
  exit 1
fi

if [ -z "$APPLICATION" ]; then
  echo "Please specify the application to deploy for."
  usage
  exit 1
fi

echo "Deploying secrets key for the application $APPLICATION in the $ENVIRONMENT environment..."

${ROOT_DIR}/scripts/deploy-sam-stack.sh \
    --account $ENVIRONMENT \
    --build \
    --stack-name "onboarding-infrastructure-secrets-key-$APPLICATION-$ENVIRONMENT${LOCAL_NAME:-}" \
    --template "${BASE_DIR}/key.template.yml" \
    --parameters Environment="$ENVIRONMENT" LocalName="${LOCAL_NAME:-''}" Application="$APPLICATION" \
    --tags sse:component="onboarding-infrastructure-keys-$APPLICATION" sse:application=$APPLICATION sse:stack-type=infrastructure sse:stack-role=keys sse:deployment-source=manual
