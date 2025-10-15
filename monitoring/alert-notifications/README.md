# Alert notifications

This component is responsible for sending alerts to the relevant notification channels:

- slack
- email groups
- pagerduty
- logs

## Pre-requisites

This stack requires the following parameters to be set before deploying this stack:

- /onboarding-infrastructure/monitoring/slack-webhook-path
- /onboarding-infrastructure/monitoring/slack-channel
- /onboarding-infrastructure/monitoring/notification-email-address

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
./scripts/deploy-alert-notifications.sh
```
