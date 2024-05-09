#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"

set -eu

# Deploy each of the application configuration pipelines.
${BASE_DIR}/../deploy-pipeline.sh -n adoption-sse-config -r adoption-application-config -s "SSM"
${BASE_DIR}/../deploy-pipeline.sh -n adoption-pp-config -r adoption-application-config -s "SSM"
