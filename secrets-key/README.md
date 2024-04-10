# Secrets Key

Deploys a KMS key to use for encrypting secrets for each application, each application should have its own key.

Only lambda and ecs services will be able to decrypt with the key through AWS Secrets Manager.

## Deploy

Deploy with:

```
export APPLICATION='product-pages'
export ENVIRONMENT='development'
./deploy-sam-stack.sh \
    --account $ENVIRONMENT \
    --build \
    --stack-name onboarding-infrastructure-secrets-key-$APPLICATION-$ENVIRONMENT \
    --template secrets-key/key.template.yml \
    --parameters Environment="$ENVIRONMENT" Application="$APPLICATION" \
    --tags sse:component="onboarding-infrastructure-keys-$APPLICATION" sse:application=$APPLICATION sse:stack-type=infrastructure sse:stack-role=keys sse:deployment-source=manual
```