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
            console.log('Successfully sent the Canary message to Slack');
        });
    } catch (error) {
        console.error('Error sending message to Slack');
        throw error;
    }
}

function getSlackPayload(record: SNSEventRecord): object {
    const message = getMessage(record.Sns.Message);

    return {
        channel: process.env.SLACK_CHANNEL,
        username: 'SSE - Heartbeat Alert',
        icon_emoji: ':canary-pie:',
        attachments: [
            {
                color: message.colour,
                blocks: [
                    {
                        type: 'section',
                        text: { type: 'mrkdwn', text: message.text }
                    },
                    {
                        type: 'context',
                        elements: [{ type: 'mrkdwn', text: message.endpoint }]
                    }
                ]
            }
        ]
    };
}

function getMessage(rawMessage: string) {
    const snsMessage = JSON.parse(rawMessage);
    const alarm: string = snsMessage.AlarmName

    type ServiceMap = { name: string, endpoint: string };
    let service: ServiceMap = {
        name: 'Onboarding',
        endpoint: 'https://www.sign-in.service.gov.uk/#'
    }

    console.log(`Getting the message for alarm ${alarm}`);
    if (alarm === 'OnboardingSelfServiceProductionHealth') {
        let service: ServiceMap = {
            name: 'Self-service tool (production)',
            endpoint: 'https://admin.sign-in.service.gov.uk/'
        }
    }
    else if (alarm === 'OnboardingSelfServiceIntegrationHealth') {
        let service: ServiceMap = {
            name: 'Self-service tool (integration)',
            endpoint: 'https://admin.integration.sign-in.service.gov.uk/'
        }
    }
    else if (alarm === 'OnboardingProductPagesProductionHealth') {
        let service: ServiceMap = {
            name: 'Product pages (production)',
            endpoint: 'https://www.sign-in.service.gov.uk/'
        }
    }
    else if (alarm === 'OnboardingProductPagesIntegrationHealth') {
        let service: ServiceMap = {
            name: 'Product pages (integration)',
            endpoint: 'https://integration.sign-in.service.gov.uk/'
        }
    }

    if (snsMessage.NewStateValue !== 'OK') {
        return {
            text: `*${alarm}* has detected that the service *${service.name}* has stopped working`,
            colour: Colour.Red,
            endpoint: `:govuk: <${service.endpoint}|View page>`
        };
    }

    if (snsMessage.OldStateValue === 'INSUFFICIENT_DATA') {
        return {
            text: `*${alarm}*  has detected that the service *${service.name}* is starting up`,
            colour: Colour.Yellow,
            endpoint: `:govuk: <${service.endpoint}|View page>`
        };
    }

    return {
        text: `*${alarm}* has detected that the service *${service.name}* is now running again`,
        colour: Colour.Green,
        endpoint: `:govuk: <${service.endpoint}|View page>`
    };
}

enum Colour {
    Green = '#36a64f',
    Yellow = '#f2c744',
    Red = '#d92e20'
}
