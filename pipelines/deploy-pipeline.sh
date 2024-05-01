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
    -n      --stack-name        [required] The name of the cloudformation or sam stack that this pipeline deploys.
    -r      --repository        [required] The name of the the GitHub repository which initiates this pipeline.
    -t      --tags              [optional] A list of tags to associate with the stack, encoded as key-value pairs delimited by '|' or newlines".
    -s      --services          [optional] A list of list of services to enable for this pipeline, delimited by '|' or newlines.
                                Core services included: CloudFormation, CloudWatch, Logs, CodeBuild, IAM, KMS,
                                S3, Secrets Manager and Textract.
                                Allowed values (maximum 7):
                                    - Athena & Glue
                                    - Athena, Glue & Redshift
                                    - Cognito
                                    - DynamoDB
                                    - ECR & ECS
                                    - EC2
                                    - EventBridge
                                    - Firehose & Kinesis
                                    - Lambda
                                    - PerformanceTest
                                    - QuickSight
                                    - SNS
                                    - SSM
                                    - StepFunctions
                                    - SQS
                                    - Xray
    -h      --help              Prints this help message and exits
EOF
}

# Set default values.
PIPELINE_STACK="https://template-storage-templatebucket-1upzyw6v9cs42.s3.amazonaws.com/sam-deploy-pipeline/template.yaml"
SUPPORT_STACK_NAME="secure-pipelines-support"

while [[ -n "${1:-}" ]]; do
  case $1 in
    -n | --stack-name)
      shift
      STACK_NAME="${1:0:23}" # Must be less than 23 characters
      TRUNCATED_STACK_NAME="${STACK_NAME:0:14}-pipeline" # Must be less than 23 characters
      PIPELINE_STACK_NAME="${STACK_NAME}-pipeline"
      ;;
    -r | --repository)
      shift
      REPOSITORY="$1"
      ;;
    -t | --tags)
      shift
      IFS='|' read -ra TAGS <<< "$1"
      ;;
    -s | --services)
      shift
      IFS='|' read -ra SERVICES <<< "$1"
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
  [[ "$account" == "$INITIAL_ACCOUNT" ]] && repository_name=$REPOSITORY || repository_name="none"
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
}

# The additional signing configuration.
function get-additional-signing-config {
  additional_code_signing_arns="arn:aws:signer:eu-west-2:216552277552:/signing-profiles/DynatraceSigner/5uwzCCGTPq"
  custom_kms_key_arns="arn:aws:kms:eu-west-2:216552277552:key/4bc58ab5-c9bb-4702-a2c3-5d339604a8fe"
}

# The support configuration from the current account.
function get-support-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)

  local output_params=$(aws cloudformation describe-stacks \
    --stack-name "$SUPPORT_STACK_NAME" --query "Stacks[0].Outputs[]" 2> /dev/null)

  # The environment value for the development account is actually 'dev'.
  [[ $account == "development" ]] && environment="dev" || environment=$account
  [[ -n "$output_params" ]] && slack_notification_stack=$(get-param "$output_params" SlackNotificationsStackName) || slack_notification_stack="none"
}

# The source configuration must come from the upstream account.
function get-source-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)
  local upstream_account=$(${ROOT_DIR}/scripts/aws.sh get-upstream-account)
  local upstream_account_number=$(${ROOT_DIR}/scripts/aws.sh get-account-number "$upstream_account")
  local upstream_account_profile=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$upstream_account_number")

  local output_params=$(aws cloudformation describe-stacks \
    --profile $upstream_account_profile \
    --stack-name "$PIPELINE_STACK_NAME" --query "Stacks[0].Outputs[]" 2> /dev/null)

  [[ -n "$output_params" ]] && [[ "$account" != "$INITIAL_ACCOUNT" ]] \
    && source_bucket=$(get-param "$output_params" ArtifactPromotionBucketArn) || source_bucket="none"
  [[ -n "$output_params" ]] && [[ "$account" != "$INITIAL_ACCOUNT" ]] \
    && source_event_trigger_role=$(get-param "$output_params" ArtifactPromotionBucketEventTriggerRoleArn) || source_event_trigger_role="none"
}

# The promotion configuration must come only if there are downstream accounts.
function get-promotion-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)
  downstream=($(${ROOT_DIR}/scripts/aws.sh get-downstream-accounts))

  if ! [[ -z "${downstream[*]}" ]]; then
    # Convert the downstream account names into account numbers
    for a in "${downstream[@]}"; do
      local downstream_account_numbers+=($(${ROOT_DIR}/scripts/aws.sh get-account-number $a))
    done
  fi

  ! [[ -z "${downstream[*]}" ]] && downstream_accounts="$(IFS=,; echo "${downstream_account_numbers[*]}")" || downstream_accounts=""
  ! [[ -z "${downstream[*]}" ]] && include_promotion="Yes" || include_promotion="No"
  ! [[ -z "${downstream[*]}" ]] && notification_type="Failures" || notification_type="All"
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
  local account_name="${1:-}"
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-number "${1:-}")
  local AWS_PROFILE=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$account" "admin")

  [[ "$account" == "$INITIAL_ACCOUNT" ]] || return

  ${ROOT_DIR}/scripts/configure-github-repo.sh update-deployment-environment "$account_name"-secure-pipelines $STACK_NAME \
      GitHubActionsRoleName GitHubActionsValidateRoleArn GitHubArtifactSourceBucketName PipelineName
}

# Deploy the pipeline to a given environment.
function deploy {
  local account_name="${1:-}"
  [[ -z $account_name ]] && return 1

  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-number "$account_name")
  local is_initial_account=$(${ROOT_DIR}/scripts/aws.sh is-initial-account "$account")
  local AWS_PROFILE=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$account" "admin")

  echo "Deploying the pipeline to $account_name"

  get-supported-services
  get-support-config
  get-initial-account-config
  get-promotion-config
  get-source-config
  get-signing-config
  get-additional-signing-config
  # TODO GET VPC STACK

  # Deploy the cloudformation stack.
  ${ROOT_DIR}/scripts/deploy-cfn-stack.sh \
    --stack-name "${PIPELINE_STACK_NAME}" \
    --template-url "${PIPELINE_STACK}" \
    --tags ${TAGS[@]} \
    --parameters \
        ParameterKey=Environment,ParameterValue="'$environment'" \
        ${STACK_NAME:+ParameterKey=SAMStackName,ParameterValue="'$STACK_NAME'"} \
        ParameterKey=IncludePromotion,ParameterValue="${include_promotion:-'No'}" \
        ${downstream_accounts:+ParameterKey=AllowedAccounts,ParameterValue="'$downstream_accounts'"} \
        ${signing_profile:+ParameterKey=SigningProfileArn,ParameterValue="'$signing_profile'"} \
        ${signing_profile_version:+ParameterKey=SigningProfileVersionArn,ParameterValue="'$signing_profile_version'"} \
        ${container_signing_key:+ParameterKey=ContainerSignerKmsKeyArn,ParameterValue="'$container_signing_key'"} \
        ${additional_code_signing_arns:+ParameterKey=AdditionalCodeSigningVersionArns,ParameterValue="'$additional_code_signing_arns'"} \
        ${custom_kms_key_arns:+ParameterKey=CustomKmsKeyArns,ParameterValue="'$custom_kms_key_arns'"} \
        ${source_bucket:+ParameterKey=ArtifactSourceBucketArn,ParameterValue="'$source_bucket'"} \
        ${source_event_trigger_role:+ParameterKey=ArtifactSourceBucketEventTriggerRoleArn,ParameterValue="'$source_event_trigger_role'"} \
        ${repository_name:+ParameterKey=OneLoginRepositoryName,ParameterValue="'$repository_name'"} \
        ${slack_notification_stack:+ParameterKey=BuildNotificationStackName,ParameterValue="'$slack_notification_stack'"} \
        ${notification_type:+ParameterKey=SlackNotificationType,ParameterValue="'$notification_type'"} \
        ParameterKey=ProgrammaticPermissionsBoundary,ParameterValue="True" \
        ${vpc_stack:+ParameterKey=VpcStackName,ParameterValue="'$vpc_stack'"} \
        ${allowed_service_one:+ParameterKey=AllowedServiceOne,ParameterValue="'$allowed_service_one'"} \
        ${allowed_service_two:+ParameterKey=AllowedServiceTwo,ParameterValue="'$allowed_service_two'"} \
        ${allowed_service_three:+ParameterKey=AllowedServiceThree,ParameterValue="'$allowed_service_three'"} \
        ${allowed_service_four:+ParameterKey=AllowedServiceFour,ParameterValue="'$allowed_service_four'"} \
        ${allowed_service_five:+ParameterKey=AllowedServiceFive,ParameterValue="'$allowed_service_five'"} \
        ${allowed_service_six:+ParameterKey=AllowedServiceSix,ParameterValue="'$allowed_service_six'"} \
        ${allowed_service_seven:+ParameterKey=AllowedServiceSeven,ParameterValue="'$allowed_service_seven'"} \
        ParameterKey=PipelineEnvironmentNameEnabled,ParameterValue="No" \
        ${TRUNCATED_STACK_NAME:+ParameterKey=TruncatedPipelineStackName,ParameterValue="'$TRUNCATED_STACK_NAME'"} \
        ParameterKey=AccessLogsCustomBucketNameEnabled,ParameterValue="Yes" \

  # Deploy to the downstream account.
  if ! [[ -z "${downstream[*]}" ]]; then
    for a in ${downstream[@]}; do
      deploy $a
    done
  fi

}

# Get the default account values.
INITIAL_ACCOUNT=$(${ROOT_DIR}/scripts/aws.sh get-initial-account)

# Check the account.
echo "The pipeline will be deployed to '$INITIAL_ACCOUNT' and all downstream accounts."
deploy "$INITIAL_ACCOUNT"

update-github "$INITIAL_ACCOUNT"
