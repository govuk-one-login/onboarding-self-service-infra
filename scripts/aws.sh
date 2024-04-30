#!/usr/bin/env bash
# AWS account utils for deploying stacks
cd "$(dirname "${BASH_SOURCE[0]}")"
set -eu

function get-all-accounts {
  jq 'keys' aws-accounts.json
}

# Get all the accounts in a given pipeline group.
function get-grouped-accounts {
  local name=${1:-$(get-current-account-name)}
  local group=$(get-pipeline-group "$name")

  jq -r --arg group "$group" '.[] | select(.group==$group) | .name' aws-accounts.json
}

# Get the pipeline group provided the account name.
function get-pipeline-group {
  local name=${1:-$(get-current-account-name)}
  local pipeline_group=$(jq -r --arg name "$name" '.[] | select(.name==$name) | .group' aws-accounts.json)

  [[ ! -z "$pipeline_group" ]] && echo $pipeline_group || return 1
}

# Get all accounts downstream from the initial account.
function get-all-downstream-accounts {
  local name=${1:-$(get-current-account-name)}
  local format=${2:-"array"}
  local initial_account=$(get-initial-account "$name")
  local group=$(get-pipeline-group "$name")

  local downstream_accounts=$(jq -r --arg name "$initial_account" --arg group "$group" 'map(select((.name==$name|not) and .group==$group) | .name)' aws-accounts.json)

  local output=$([[ "$format" == "string" ]] && jq -r 'join(",")' <<< $downstream_accounts || jq -r '.[]' <<< $downstream_accounts)
  [[ -n "$downstream_accounts" ]] && [[ "${downstream_accounts}" != "null" ]] && echo $output || return 1
}

function is-initial-account {
  local name=${1:-$(get-current-account-name)}
  local is_initial_account

  [[ "$name" != $(get-initial-account "$name") ]] && is_initial_account=true && is_initial_account=false
}

# Get the initial account provided the account name.
function get-initial-account {
  local name=${1:-$(get-current-account-name)}
  local initial_account=$(jq -r --arg name "$name" '.[] | select(.name==$name) | .initial' aws-accounts.json 2> /dev/null)

  [[ ! -z "$initial_account" ]] && echo $initial_account || return 1
}

# Get the upstream account provided the account name.
function get-upstream-account {
  local name=${1:-$(get-current-account-name)}
  local upstream_account=$(jq -r --arg name "$name" '.[] | select(.name==$name) | .upstream' aws-accounts.json 2> /dev/null)

  [[ -n "$upstream_account" ]] && [[ "${upstream_account}" != "null" ]] && echo $upstream_account || return 1
}

# Get the downstream accounts provided the account name.
function get-downstream-accounts {
  local name=${1:-$(get-current-account-name)}
  local format=${2:-"array"}
  local downstream_accounts=$(jq -r --arg name "$name" '.[] | select(.name==$name) | .downstream' aws-accounts.json 2> /dev/null)

  local output=$([[ "$format" == "string" ]] && jq -r 'join(",")' <<< $downstream_accounts || jq -r '.[]' <<< $downstream_accounts)
  [[ -n "$downstream_accounts" ]] && [[ "${downstream_accounts}" != "null" ]] && echo $output || return 1
}

# Get the account number provided the account name.
function get-account-number {
  local name=${1:-$(get-current-account-name)}
  local account_number=$(jq -r --arg name "$name" '.[] | select(.name==$name) | .account' aws-accounts.json 2> /dev/null)

  [[ ! -z "$account_number" ]] && echo $account_number || return 1
}

# Get the account name provided the account number.
function get-account-name {
  local account=${1:-$(get-current-account-number)}
  local account_name=$(jq -r --arg account "$account" '.[] | select(.account==($account|tonumber)) | .name' aws-accounts.json 2> /dev/null)

  [[ ! -z "$account_name" ]] && echo $account_name || return 1
}

# Get the aws profile configured for a given account number.
function get-account-profile {
  local account=${1:-$(get-current-account-number)}
  local role="di-onboarding-${2:-readonly}" # Use readonly roles unless specified.

  for p in $(aws configure list-profiles); do
    local profile=$(aws --profile "$p" sts get-caller-identity 2> /dev/null)
    if [[ $(jq -r ".Account" <<< "$profile") == "$account" ]] \
    && [[ $(jq -r ".Arn" <<< "$profile") =~ "$role" ]]
    then
      echo $p
      break
    fi
  done
}

# Get caller identity.
function get-caller-identity {
  local aws_account=$(aws sts get-caller-identity --output text --query "Account" 2> /dev/null)
  local identity=$(aws sts get-caller-identity)
  
  # Only return the caller identity if the account was valid.
  [[ -n "$aws_account" ]] && [[ -n $(jq -r ".Account" <<< "$identity") ]] && echo $identity && return

  echo "Valid AWS credentials were not found in the environment" >&2
  echo "Authenticate with AWS using SSO and try again" >&2
  echo "https://govukverify.atlassian.net/l/cp/rq8xkV2B" >&2
  return 255
}

# Verify the user has access
function check-current-account {
  [[ get-caller-identity > /dev/null ]] && echo true || echo false
}

# Get the account number for the active account.
function get-current-account-number {
  local identity=$(get-caller-identity)
  jq -r ".Account" <<< "$identity"
}

# Get the account name for the active account.
function get-current-account-name {
  local account=$(get-current-account-number)
  get-account-name $account
}

# Get the user name of the current user.
function get-user-name {
  local identity=$(get-caller-identity) || exit
  local arn=$(jq -r ".Arn" <<< "$identity")
  [[ $arn =~ assumed-role\/([0-9a-zA-z._-]+)\/([0-9a-zA-z._-]+) ]] && echo "${BASH_REMATCH[2]}"
}

# Get outputs from another cloudformation stack.
function get-stack-outputs {
  local stack=$1
  local selectors=${*:2}
  local query

  for selector in $selectors; do
    query+="${query:+ || }contains(OutputKey, '$selector')"
  done

  local query=${query:+?${query}}
  local outputs=$(aws cloudformation describe-stacks --stack-name "$stack" --query "Stacks[0].Outputs[$query]" 2> /dev/null)
  [[ $outputs != null ]] && [[ $outputs != "[]" ]] && jq 'map({name: .OutputKey, value: .OutputValue}) | .[]' <<< "$outputs"
}

# Check caller identity first.
[[ $* ]] || check-current-account
# Run the appropriate commands.
[[ $* ]] && "$@"
