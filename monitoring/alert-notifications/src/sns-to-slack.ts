import { SNSEvent, Context, SNSHandler, SNSEventRecord } from 'aws-lambda'
import axios from 'axios';

export const lambdaHandler: SNSHandler = async (event: SNSEvent, context: Context): Promise<void> => {
    for (const record of event.Records) {
        await sendSlackNotification(record, context);
    }
    console.info("done");
};

async function sendSlackNotification(record: SNSEventRecord, context: Context): object {
    try {
        const httpClient = axios.create({
            baseURL: 'https://hooks.slack.com/',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        const slackPayload = getSlackPayload(record);
        const webhookPath = process.env.SLACK_WEBHOOK_PATH!;
        return httpClient.post(webhookPath, slackPayload).then(() => {
            console.log('Successfully sent the alert message to Slack');
        });
    } catch (error) {
        console.error('Error sending message to Slack');
        throw error;
    }
}

function getSlackPayload(record: SNSEventRecord): object {
    const message = getMessage(record.Sns.Message);

    let payload = {
        channel: process.env.SLACK_CHANNEL,
        username: message.application || 'Onboarding alerts',
        icon_emoji: message.icon || ':govuk:',
        attachments: [
            {
                color: message.colour || Colour.Green,
                blocks: [ ]
            }
        ]
    };

    if (message.heading) {
        let block = {
            type: 'header',
            text: { type: 'plain_text', text: message.heading }
        }
        payload.attachments[0].blocks.push(block)
    }
    if (message.body) {
        let block = {
            type: 'section',
            text: { type: 'mrkdwn', text: message.body }
        }
        payload.attachments[0].blocks.push(block)
    }
    if (message.context) {
        let block = {
            type: 'context',
            elements: [{ type: 'mrkdwn', text: message.context }]
        }
        payload.attachments[0].blocks.push(block)
    }

    return payload;
}

function getMessage(rawMessage: string) {
    const sns = JSON.parse(rawMessage);

    let message = {
        icon: sns.Emoji || ':govuk:',
        application: sns.Application || 'Onboarding Alerts',
        heading: sns.Heading,
        body: sns.Message,
        context: sns.Context,
        colour: Colour[sns.Colour] || Colour.Green,
    };

    return message;
}

enum Colour {
    Green = '#36a64f',
    Yellow = '#f2c744',
    Amber = '#ff7a17',
    Red = '#d92e20',
    Neutral = '#8c8c8c'
}
