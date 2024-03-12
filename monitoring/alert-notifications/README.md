# Alert notifications

This component is responsible for sending alerts to the relevant notification channels:

- slack
- email groups
- pagerduty
- logs

## Sending alerts

This component publishes an SNS topic ARN to the SSM Param `/onboarding/monitoring/alert-notification-topic`.

To send out notifications other alert sources can publish messages to this topic in the following format:

```json
{
    "Application": "String",
    "Heading": "String",
    "Message": "String<mrkdown>",
    "Context": "String<mrkdown>",
    "Colour": "Green|Amber|Red|Neutral"
}
```

## Deploy

The notification stack is deployed once in each environment, but will only :

```
./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-alert-notifications \
    --base-dir monitoring/alert-notifications \
    --template monitoring/alert-notifications/alert-notifications.template.yml
```