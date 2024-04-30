#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"

set -eu

# Deploy each of the application configuration pipelines.
${BASE_DIR}/../deploy-pipeline.sh -n onboarding-sse-config -r onboarding-self-service-config -s "SSM"
${BASE_DIR}/../deploy-pipeline.sh -n onboarding-pp-config -r onboarding-self-service-config -s "SSM"
