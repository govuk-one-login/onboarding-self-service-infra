# Onboarding Secure Pipelines

Secure Pipelines provide a way to promote to higher environments with restricted permissions.

See [User Guides for Secure Pipelines](https://govukverify.atlassian.net/wiki/spaces/PLAT/pages/3059908609/How+to+deploy+a+SAM+application+with+secure+pipelines) for more information.

### Prerequisites

- Sign in with [`aws sso`](https://govukverify.atlassian.net/wiki/spaces/PLAT/pages/3554280423/Getting+Ready+for+AWS+SSO)

## Create or update a pipeline

Secure pipelines will be deployed to all accounts within the build pipeline, specify the name of the SAM stack that will be deployed with the pipeline, not the name of the pipeline stack:

```
./deploy-pipeline.sh \
    --stack-name new-stack \
    --repository onboarding-self-service-infra
    --services "ECR & ECS" "SSM"
```
