#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
set -eu

# NOTE: This is the new draft deployment script. WIP.

# Deploy the product-pages pipeline.
${BASE_DIR}/../deploy-pipeline.sh -n productpages-frontend -r onboarding-product-page -s "ECR & ECS|Cognito|DynamoDB"