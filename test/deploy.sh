#!/usr/bin/env bash

# Utility script to deploy secrets-key stack
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."

set -e
set -o pipefail

echo "Deploying test stack..."

${ROOT_DIR}/scripts/deploy-sam-stack.sh \
    --account $ENVIRONMENT \
    --no-build \
    --validate \
    --stack-name "onboarding-infra-test-config" \
    --template "test.template.yml" \
    --parameters Environment="${ENVIRONMENT}" \
    --tags sse:component="onboarding-infrastructure-test-config" sse:stack-type=infrastructure sse:stack-role=test sse:deployment-source=manual

