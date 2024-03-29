# Canary SNS to Slack

This lambda subscribes to an SNS topic.

SNS delivers a notification which contains amongst other things a message. The message is a stringified JSON object.

This lambda translates the message to something Slack will accept and then sends it to slack.

## Sample messages to test the SNS to Slack function

Sample test message to post to the Canary SNS topic.

```json
{
    "Emoji": "String<:emoji:>",
    "Application": "String",
    "Heading": "String",
    "Message": "String<mrkdown>",
    "Context": "String<mrkdown>",
    "Colour": "Green|Yellow|Amber|Red|Neutral"
}
```

Sample test message to post directly to the Slack lambda function - this mimics the SNS message that triggers the lambda.

```json
{
    "Records": [
        {
            "Sns": {
                "Message": "{\"Application\":\"DI SSE Test Alerts\",\"Message\":\"Test message\",\"Colour\":\"Green\"}"
            }
        }
    ]
}
```
