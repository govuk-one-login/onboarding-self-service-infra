# WAF

This is the WAF for all frontend SSE applications.

Please read the developer guide, as all WAFs should be deployed in Count mode, then upgraded to Block after testing.

https://docs.aws.amazon.com/waf/latest/developerguide/getting-started.html

## Simple use

To use this, simply comment out the rules that you no longer want to be in Count mode, and they'll follow the default action of their managed group.

Please read the documentation on AWS for the managed groups, and validate your key behaviours before running unsupervised in production.

Please also review the RuleGroups in the WAF console to ensure that the actions are appropriate, and ensure that the overrideAction for the ManagedRuleSets is set to None.

## Testing

The tests folder contains some example tests to get you started, but to lock rules in and ensure those exist, please extend the test suite to match your implementation.

## Checkov

Please also run checkov against the template to ensure that you're as secure as possible.  Any false positives that you need to skip should be reconfirmed with tests. (e.g. the Log4J check).

## Deploy

This component should be deployed for the appropriate application (set `$APPLICATION` to `self-service` or `product-pages`), with:
onboarding-infrastructure-waf-product-pages-    
development
```
export APPLICATION='product-pages'
export ENVIRONMENT='build'
./scripts/deploy-sam-stack.sh \
    --account $ENVIRONMENT \
    --build \
    --stack-name onboarding-infrastructure-waf-"$APPLICATION"-"$ENVIRONMENT" \
    --template waf/waf.template.yml \
    --manifest waf/package.json \
    --parameters Environment="$ENVIRONMENT" Application="$APPLICATION" \
    --tags sse:component="onboarding-infrastructure-waf-$APPLICATION" sse:application=$APPLICATION sse:stack-type=infrastructure sse:stack-role=waf sse:deployment-source=manual
```

### Parameters
The list of parameters for this template:

| Parameter   | Type   | Default   | Description                                                           |
|-------------|--------|-----------|-----------------------------------------------------------------------|
| Environment | String | dev | The environment we're deploying into.                                 |
| Application | String | dev | The name of the application, either 'self-service' or 'product-pages'. |


### Resources
The list of resources this template creates:

| Resource         | Type   |
|------------------|--------|
| webAcl | AWS::WAFv2::WebACL |
| cloudwatchLogsGroup | AWS::Logs::LogGroup |
| CSLScloudwatchLogsGroup | AWS::Logs::SubscriptionFilter |
| webAcllogging | AWS::WAFv2::LoggingConfiguration |
| WafAclSSM | AWS::SSM::Parameter |
| WAFLoggingKmsKey | AWS::KMS::Key |


### Outputs
The list of outputs this template exposes:

| Output           | Description   |
|------------------|---------------|
| OnboardingWebAclArn | ARN of WebACL |
| CloudwatchLogsGroupArn | ARN of CloudWatch Logs Group |

The SSM parameter `/onboarding-infrastructure/waf/${Application}-acl-arn` is created for use by other applications.
