#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="${BASE_DIR}/../../.."
set -eu

function get-param {
  jq --raw-output --arg name "$2" '.[] | select(.OutputKey == $name) | .OutputValue' <<< "$1"
}

function get-signing-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)
  local initial_account_number=$(${ROOT_DIR}/scripts/aws.sh get-account-number "$INITIAL_ACCOUNT")
  local initial_account_profile=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$initial_account_number")

  local output_params=$(aws cloudformation describe-stacks \
    --profile $initial_account_profile \
    --stack-name secure-pipelines-support --query "Stacks[0].Outputs[]" 2> /dev/null)

  signing_profile=$(get-param "$output_params" SigningProfileARN)
  signing_profile_version=$(get-param "$output_params" SigningProfileVersionARN)
  container_signing_key=$(get-param "$output_params" ContainerSigningKeyARN)
}

function get-source-config {
  local account=$(${ROOT_DIR}/scripts/aws.sh get-account-name)
  local upstream_account=$(${ROOT_DIR}/scripts/aws.sh get-upstream-account)
  local upstream_account_number=$(${ROOT_DIR}/scripts/aws.sh get-account-number "$upstream_account")
  local upstream_account_profile=$(${ROOT_DIR}/scripts/aws.sh get-account-profile "$upstream_account_number")

  local output_params=$(aws cloudformation describe-stacks \
    --profile $upstream_account_profile \
    --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[]" 2> /dev/null)

  frontend_source_bucket=$(get-param "$output_params" ProductPagesFrontendPromotionBucket)

  [[ -n "$output_params" ]] && [[ "$account" != "$INITIAL_ACCOUNT" ]] \
    && source_event_trigger_role=$(get-param "$output_params" ProductPagesFrontendPromotionBucketEventTriggerRoleArn) || source_event_trigger_role="none"
}

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
}

ACCOUNT=$(${ROOT_DIR}/scripts/aws.sh get-current-account-name)
INITIAL_ACCOUNT=$(${ROOT_DIR}/scripts/aws.sh get-initial-account "$ACCOUNT")
STACK_NAME=productpages-secure-pipelines

[[ $ACCOUNT == "$INITIAL_ACCOUNT" ]] || get-source-config
[[ $ACCOUNT == "$INITIAL_ACCOUNT" ]] && repo_name="onboarding-product-page"
[[ $ACCOUNT == development ]] && ENV=dev || ENV=$ACCOUNT

get-signing-config
get-promotion-config

${ROOT_DIR}/scripts/deploy-sam-stack.sh "$@" \
  --validate \
  --stack-name "$STACK_NAME" \
  --template ${BASE_DIR}/deployment-pipelines.template.yml \
  --tags Product="GOV.UK One Login" System="Orchestration" Service="Product Pages" Owner="di-dfa-tech@digital.cabinet-office.gov.uk" Environment="$ENV" \
  --parameters Environment="$ENV" NextAccount="${downstream_accounts:-''}" \
  OneLoginRepositoryName="${repo_name:-none}" \
  SigningProfileARN="${signing_profile:-none}" \
  SigningProfileVersionARN="${signing_profile_version:-none}" \
  ProductPagesFrontendSourceBucketARN="${frontend_source_bucket:-none}" \
  ProductPagesFrontendArtifactSourceBucketEventTriggerRoleArn="${source_event_trigger_role:-none}" \
  ContainerSigningKeyARN="${container_signing_key:-none}"

if [[ $ACCOUNT == "$INITIAL_ACCOUNT" ]]; then
  ${ROOT_DIR}/scripts/configure-github-repo.sh update-deployment-environment "$ACCOUNT"-secure-pipelines $STACK_NAME \
    DeploymentRoleArn ArtifactSourceBucketName FrontendECRRepositoryName PipelineName
fi
