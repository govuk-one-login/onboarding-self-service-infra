#!/usr/bin/env bash
# shellcheck disable=SC2016
# Set up the GitHub repo to work with secure pipelines
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
set -eu

function update-subject-claim-template {
  echo "➡ Updating OIDC subject claim customisation template"
  local api_path="/repos/{owner}/{repo}/actions/oidc/customization/sub"
  local subject_claim_template='{"use_default":false,"include_claim_keys":["repo","context","ref"]}'

  echo The current template is
  gh api $api_path && echo

  echo Applying new template...
  gh api $api_path --method PUT --input - <<< "$subject_claim_template" > /dev/null
  gh api $api_path
}

function update-deployment-environment {
  local env=$1 stack=$2 outputs=${*:3}
  write-github-actions-variables "$env" "$(${BASE_DIR}/aws.sh get-stack-outputs "$stack" "$outputs")"
}

function check-deployment-environment-config {
  local env=$1 api_path="/repos/{owner}/{repo}/environments/$1" policy
  [[ $env =~ development ]] || policy='{"protected_branches":true,"custom_branch_policies":false}'
  gh api --method PUT "$api_path" --input - < <(jq '{deployment_branch_policy: .}' <<< "${policy:-null}") > /dev/null
}

function write-github-actions-variables {
  local env=$1 outputs=${*:2} repo_id api_path name variable value current_value
  [[ $(xargs <<< "$outputs") ]] && ${BASE_DIR}/aws.sh is-initial-account || exit 1

  repo_id=$(gh api "/repos/{owner}/{repo}" --jq .id)
  api_path=/repositories/$repo_id/environments/$env/variables

  echo "➡ Updating GitHub Actions deployment environment '$env'"
  check-deployment-environment-config "$env"

  for name in $(jq --raw-output '.name' <<< "$outputs"); do
    value=$(jq --raw-output --arg name "$name" 'select(.name == $name) | .value' <<< "$outputs")

    # Split a camelCase stack output name on word boundaries, insert underscores and capitalise
    variable=$(sed -E -e "s/(.)([A-Z][a-z])/\1_\2/g" -e "s/([a-z])([A-Z])/\1_\2/g" <<< "$name" | tr "[:lower:]" "[:upper:]")

    if current_value=$(gh api "$api_path/$variable" --jq .value 2> /dev/null); then
      [[ $current_value == "$value" ]] && continue || echo "Updating $variable..."
      gh api --method PATCH "$api_path/$variable" -f name="$variable" -f value="$value"
      continue
    fi

    echo "Creating $variable..."
    gh api --method POST "$api_path" -f name="$variable" -f value="$value" > /dev/null
  done

  echo "--- Variables ---"
  gh api "$api_path" --jq '.variables | map([.name, .value] | join(": ")) | .[]'
}

[[ $* ]] || update-subject-claim-template
[[ $* ]] && "$@"
