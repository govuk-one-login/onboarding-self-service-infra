# SSM Parameter & Secrets Manager Secret Changes

Any changes to ssm parameters or secrets manager secrets that are used by either application should alert the attention of developers.

## Application parameters & secrets

All parameters used by the applications should be prefixed in the following way:

- `/self-service/`
- `/product-pages/`


## Deploy

This component should be deployed to both integration and production accounts, with:

```
./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-parameter-changes \
    --base-dir monitoring/parameter-changes \
    --template monitoring/parameter-changes/parameter-changes.template.yml
```
