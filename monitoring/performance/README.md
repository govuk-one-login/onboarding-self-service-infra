# Smoke Tests

The performance alarms are set to identify poorly performing front ends for both applications. They do not currently alert but can be used to check on stack performance.

## Deploy

The alarms can be deployed with:

```
./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-performance-alarms \
    --base-dir monitoring/performance \
    --template monitoring/performance/performance.template.yml
```