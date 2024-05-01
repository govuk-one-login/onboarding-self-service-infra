#!/usr/bin/env bash

# Utility script to deploy a new secure pipeline stack
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/.."
set -eu

usage() {
  cat << 'EOF'
This script deploys a secure pipeline stack.

The pipeline will be deployed to all accounts in the secure pipelines account group starting from the initial account.

Usage:
    -n      --stack-name        [required] The name of the stack that uses this repository.
    -t      --tags              [optional] A list of tags to associate with the stack, encoded as key-value pairs delimited by '|' or newlines".
    -h      --help              Prints this help message and exits
EOF
}

# Set default values.
PIPELINE_STACK="https://template-storage-templatebucket-1upzyw6v9cs42.s3.amazonaws.com/container-image-repository/template.yaml"
SUPPORT_STACK_NAME="secure-pipelines-support"

while [[ -n "${1:-}" ]]; do
  case $1 in
    -n | --stack-name)
      shift
      STACK_NAME="${1:0:23}" # Must be less than 23 characters
      ECR_STACK_NAME="${STACK_NAME}-ecr"
      PIPELINE_STACK_NAME="${STACK_NAME}-pipeline"
      ;;
    -t | --tags)
      shift
      IFS='|' read -ra TAGS <<< "$1"
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

if [[ -z ${STACK_NAME+x} ]] || [[ -z ${REPOSITORY+x} ]]; then
  echo -e "Missing required parameters.\n"
  usage
  exit 1
fi

function get-param {
  jq --raw-output --arg name "$2" '.[] | select(.OutputKey == $name) | .OutputValue' <<< "$1"
}

function update-github {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-number "${1:-}")
  local AWS_PROFILE=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$account" "admin")

  [[ "$account" == "$INITIAL_ACCOUNT" ]] || return

  ${ROOT_DIR}/scripts/configure-github-repo.sh update-deployment-environment "$account_name"-secure-pipelines $ECR_STACK_NAME \
      ContainerRepositoryName
}

# Deploy the pipeline to a given environment.
function deploy {
  local account_name="${1:-}"
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-number "$account_name")
  local AWS_PROFILE=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$account" "admin")

  echo "Deploying the container repository to $account_name"

  # Deploy the cloudformation stack.
  ${ROOT_DIR}/scripts/deploy-cfn-stack.sh \
    --stack-name "${ECR_STACK_NAME}" \
    --template-url "${PIPELINE_STACK}" \
    --parameters \
        ParameterKey=PipelineStackName,ParameterValue="$PIPELINE_STACK_NAME"

}

# Get the default account values.
INITIAL_ACCOUNT=$(${ROOT_DIR}/scripts/aws.sh get-initial-account)

# Check the account.
echo "The ecr will be deployed to '$INITIAL_ACCOUNT' account only."
deploy $INITIAL_ACCOUNT
