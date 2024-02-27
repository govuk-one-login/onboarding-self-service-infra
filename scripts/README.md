# Utility Scripts

These scripts will provide support for common functionality.

## `deploy-sam-stack.sh`

This script will deploy a given sam stack. Usage example:

```
./deploy-sam-stack.sh \
    --account build \
    --build \
    --stack-name onboarding-infrastructure-component-stack-name \
    --base-dir infrastructure/component \
    --template infrastructure/component/template.yml
```