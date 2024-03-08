# Canary SNS to Slack

This lambda subscribes to an SNS topic.

SNS delivers a notification which contains amongst other things a message. The message is a stringified JSON object.

This lambda translates the message to something Slack will accept and then sends it to slack.

## Sample messages to test the SNS to Slack function

Sample test message to post to the Security Findings SNS topic.

```json
{
  "detail": {
    "findings": [{
      "AwsAccountId": "123456789012",
      "Title": "Google Suite Two-Factor Backup Codes uploaded to S3",
      "ProductFields": {
        "aws/securityhub/SeverityLabel": "LOW",
        "aws/securityhub/ProductName": "Macie"
      },
      "RecordState": "ACTIVE"
    }]
  }
}
```

Sample test message to post directly to the Slack lambda function - this mimics the SNS message that triggers the lambda.

```json
{
    "Records": [
        {
            "Sns": {
                "Message": "{\"AlarmName\":\"TestAlarmName\",\"NewStateValue\":\"OK\",\"OldStateValue\":\"test\"}"
            }
        }
    ]
}
```
