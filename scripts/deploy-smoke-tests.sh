./scripts/deploy-sam-stack.sh \
 --account development \
 --build \
 --stack-name onboarding-infrastructure-monitoring-smoke-tests \
 --base-dir monitoring/smoke-tests \
 --template monitoring/smoke-tests/smoke-tests.template.yml \
 --manifest monitoring/smoke-tests/src/package.json