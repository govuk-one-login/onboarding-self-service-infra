#!/usr/bin/env bash
# Utility script to deploy SAM stacks
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
set -e -o pipefail

OPTION_REGEX="^--?.*"
DEPLOY=true

while [[ -n "$1" ]]; do
  case $1 in
    -n | --stack-name)
      [[ -z ${2:-} || $2 =~ $OPTION_REGEX ]] && echo "Invalid stack name: '$2'" && exit 1
      shift && STACK_NAME=$1
      ;;
    -t | --tags)
      while [[ $2 ]] && ! [[ $2 =~ $OPTION_REGEX ]]; do
        shift && TAGS+=("$1")
      done
      ;;
    -o | --params | --parameters | --parameter-overrides)
      while [[ $2 ]] && ! [[ $2 =~ $OPTION_REGEX ]]; do
        shift && PARAMS+=("$1")
      done
      ;;
    -f | --template | --template-file) shift && TEMPLATE=$1 && unset TEMPLATE_URL ;;
    -u | --template-url) shift && TEMPLATE_URL=$1 && unset TEMPLATE ;;
    -a | --account) shift && ACCOUNT=$1 ;;
    -r | --disable-rollback) DISABLE_ROLLBACK=true ;;
    --no-delete-rollback-complete) DELETE_ON_FAILED_CREATION=false ;;
    *) echo "Unknown option '$1'" && exit 1 ;;
  esac
  shift
done

function get-pipeline-stack-status {
  echo "$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].StackStatus" --output text 2> /dev/null || echo "NO_STACK")"
}

function create-or-update {
  local pipeline_stack_state="$(get-pipeline-stack-status)"
  create_or_update=$([[ $pipeline_stack_state != "NO_STACK" ]] && echo update || echo create)
}

function deploy {
  create-or-update

  output="$(aws cloudformation "$create_or_update"-stack \
      --stack-name="$STACK_NAME" \
      --template-url="$TEMPLATE_URL" \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
      ${TAGS:+--tags ${TAGS[@]}} \
      ${PARAMS:+--parameters ${PARAMS[@]}} \
      2>&1 \
          && aws cloudformation wait stack-"$create_or_update"-complete \
              --stack-name="$STACK_NAME" || echo "Error" )"

  if [[ "$output" =~ "ValidationError" ]] && [[ ! "$output" =~ "No updates are to be performed" ]]; then
    echo "Pipeline stack '$STACK_NAME' failed with output:"
    echo "$output"
    exit 1
  fi

  pipeline_stack_state="$(get-pipeline-stack-status)"
  if [[ "$pipeline_stack_state" = "UPDATE_ROLLBACK_COMPLETE" ]]; then
    echo "Pipeline stack '$STACK_NAME' failed to update!"
    exit 1
  fi
  if [[ "$pipeline_stack_state" = "ROLLBACK_COMPLETE" ]]; then
    echo "Pipeline stack '$STACK_NAME' failed to create!"
    exit 1
  fi
}

$DEPLOY && ! ${BASE_DIR}/aws.sh check-current-account "${ACCOUNT:-}" 2> /dev/null &&
  echo "Authenticate to${ACCOUNT:+" the '$ACCOUNT' account in"} AWS before deploying the stack" && exit 1

[[ $TEMPLATE ]] && ! [[ -f $TEMPLATE ]] && [[ -z $TEMPLATE_URL ]] && echo "No template found" && exit 1


${DISABLE_ROLLBACK:-false} && DISABLE_ROLLBACK_OPTION="--disable-rollback"
TAGS+=(Key="sse:component",Value="infrastructure" Key="sse:deployment-source",Value="manual")

$DEPLOY || exit 0
echo "Deploying stack ${STACK_NAME} with params:"
printf "  %s\n" "${PARAMS[@]}"
echo "... and tags:"
printf "  %s\n" "${TAGS[@]}"
deploy
