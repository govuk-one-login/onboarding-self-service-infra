./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-smoke-tests-canary-alarms \
    --base-dir monitoring/smoke-tests \
    --template monitoring/smoke-tests/canary-alarms.template.yml