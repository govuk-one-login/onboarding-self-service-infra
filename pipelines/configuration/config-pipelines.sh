#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"

set -eu

# Deploy each of the application configuration pipelines.
${BASE_DIR}/../deploy-pipeline.sh \
  --stack-name adoption-sse-config \
  --repository adoption-application-config \
  --services "SSM"

${BASE_DIR}/../deploy-pipeline.sh \
  --stack-name adoption-pp-config \
  --repository adoption-application-config \
  --services "SSM"
