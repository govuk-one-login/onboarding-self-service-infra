# Security Hub Findings

Any Security Hub findings that are HIGH or CRITICAL are reported to the appropriate alerting endpoints.

## Deploy

This component should be deployed to both integration and production accounts, with:

```
./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-security-findings \
    --base-dir monitoring/security-findings \
    --template monitoring/security-findings/security-findings.template.yml
```
