#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."
set -eu

STACK_NAME=deployment-config

${ROOT_DIR}/scripts/deploy-sam-stack.sh "$@" \
  --validate \
  --account development \
  --stack-name $STACK_NAME \
  --template deployment-config.template.yml \
  --tags sse:stack-type=config sse:stack-role=deployment \
  --params GitHubOrg=govuk-one-login GitHubRepo=onboarding-self-service-experience

${ROOT_DIR}/scripts/configure-github-repo.sh update-deployment-environment development $STACK_NAME \
  DeploymentRoleARN DeploymentArtifactsBucket FrontendContainerImageRepository
