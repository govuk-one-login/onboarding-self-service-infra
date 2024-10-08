#!/usr/bin/env bash
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
set -eu

# NOTE: This is the new draft deployment script. WIP.

# Deploy the self-service experience pipelines.
${BASE_DIR}/../deploy-pipeline.sh -n self-service-dynamodb -r onboarding-self-service-experience -s "DynamoDB"
${BASE_DIR}/../deploy-pipeline.sh -n self-service-cognito -r onboarding-self-service-experience -s "Cognito|Lambda|SNS|EC2"
${BASE_DIR}/../deploy-pipeline.sh -n self-service-api -r onboarding-self-service-experience -s "Lambda|DynamoDB|SNS|StepFunctions|EC2|SQS"
${BASE_DIR}/../deploy-pipeline.sh -n self-service-frontend -r onboarding-self-service-experience -s "ECR & ECS|Cognito|DynamoDB"
