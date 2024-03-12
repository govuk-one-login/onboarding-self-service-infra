# Smoke Tests

The smoke tests regularly probe the application endpoints to ensure they are in good health.

The heartbeat check they perform verifies that the application is responding with a 2xx status.

## Deploy

Smoke tests are deployed as two components, the supporting stacks can be deployed with:

```
./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-smoke-tests \
    --base-dir monitoring/smoke-tests \
    --template monitoring/smoke-tests/smoke-tests.template.yml \
    --manifest monitoring/smoke-tests/src/package.json
```

The canary alarms are contained in a separate stack which can be deployed with:

```
./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-smoke-tests-canary-alarms \
    --base-dir monitoring/smoke-tests \
    --template monitoring/smoke-tests/canary-alarms.template.yml
```