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

# Values that should only given to the pipeline in the initial account.
function get-initial-account-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)
  [[ "$account" == "$INITIAL_ACCOUNT" ]] && repository_name=$REPOSITORY
}

# The signing configuration must come from the initial account.
function get-signing-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)
  local initial_account_number=$(${ROOT_DIR}/scripts/aws.sh get-account-number "$INITIAL_ACCOUNT")
  local initial_account_profile=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$initial_account_number")

  local output_params=$(aws cloudformation describe-stacks \
    --profile $initial_account_profile \
    --stack-name "$SUPPORT_STACK_NAME" --query "Stacks[0].Outputs[]" 2> /dev/null)

  [[ -n "$output_params" ]] && signing_profile=$(get-param "$output_params" SigningProfileARN) || signing_profile="none"
  [[ -n "$output_params" ]] && signing_profile_version=$(get-param "$output_params" SigningProfileVersionARN) || signing_profile_version="none"
  [[ -n "$output_params" ]] && container_signing_key=$(get-param "$output_params" ContainerSigningKeyARN) || container_signing_key="none"

  [[ -n "$output_params" ]] && slack_notification_stack=$(get-param "$output_params" SlackNotificationsStackName) || slack_notification_stack="none"
}

# The additional signing configuration.
function get-additional-signing-config {
  additional_code_signing_arns="arn:aws:signer:eu-west-2:216552277552:/signing-profiles/DynatraceSigner/5uwzCCGTPq"
  custom_kms_key_arns="arn:aws:kms:eu-west-2:216552277552:key/4bc58ab5-c9bb-4702-a2c3-5d339604a8fe"
}

# The source configuration must come from the upstream account.
function get-source-config {
  local upstream_account=$(${ROOT_DIR}/scripts/aws.sh get-upstream-account)
  local upstream_account_number=$(${ROOT_DIR}/scripts/aws.sh get-account-number "$upstream_account")
  local upstream_account_profile=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$upstream_account_number")

  local output_params=$(aws cloudformation describe-stacks \
    --profile $upstream_account_profile \
    --stack-name "$PIPELINE_STACK_NAME" --query "Stacks[0].Outputs[]" 2> /dev/null)

  [[ -n "$output_params" ]] && source_bucket=$(get-param "$output_params" ArtifactPromotionBucketArn) || source_bucket="none"
  [[ -n "$output_params" ]] && source_event_trigger_role=$(get-param "$output_params" ArtifactPromotionBucketEventTriggerRoleArn) || source_event_trigger_role="none"
}

# The promotion configuration must come only if there are downstream accounts.
function get-promotion-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)

  downstream_accounts=$(${ROOT_DIR}/scripts/aws.sh get-downstream-accounts $account string)
  for a in "${downstream_accounts[@]}"; do
    downstream_account_numbers+=($(${ROOT_DIR}/scripts/aws.sh get-account-number $a))
  done

  [[ -n $downstream_accounts ]] && include_promotion="Yes" || include_promotion="No"
  [[ -n $downstream_accounts ]] && notification_type="Failures" || notification_type="All"
}

# The additional services that can be deployed by this deployment pipeline.
function get-supported-services {
  allowed_service_one="${SERVICES[0]:-}"
  allowed_service_two="${SERVICES[1]:-}"
  allowed_service_three="${SERVICES[2]:-}"
  allowed_service_four="${SERVICES[3]:-}"
  allowed_service_five="${SERVICES[4]:-}"
  allowed_service_six="${SERVICES[5]:-}"
  allowed_service_seven="${SERVICES[6]:-}"
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
