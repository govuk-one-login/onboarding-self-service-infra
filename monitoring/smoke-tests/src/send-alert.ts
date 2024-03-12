import { SNSEvent, Context, SNSHandler, SNSEventRecord } from 'aws-lambda';
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns"

const snsClient = new SNSClient({});

export const lambdaHandler: SNSHandler = async (event: SNSEvent, context: Context): Promise<void> => {
    for (const record of event.Records) {
        await sendNotification(record, context);
    }
    console.info("done");
};

enum ProductPagesEndpoint {
    Development = 'https://development.sign-in.service.gov.uk/',
    Build = 'https://build.sign-in.service.gov.uk/',
    Staging = 'https://staging.sign-in.service.gov.uk/',
    Integration = 'https://integration.sign-in.service.gov.uk/',
    Production = 'https://www.sign-in.service.gov.uk/'
}
enum SelfServiceEndpoint {
    Development = 'https://admin.development.sign-in.service.gov.uk/',
    Build = 'https://admin.build.sign-in.service.gov.uk/',
    Staging = 'https://admin.staging.sign-in.service.gov.uk/',
    Integration = 'https://admin.integration.sign-in.service.gov.uk/',
    Production = 'https://admin.sign-in.service.gov.uk/'
}

async function sendNotification(record: SNSEventRecord, context: Context): object {
    try {
        const payload = getMessage(record);

        const response = await snsClient.send(
            new PublishCommand({
                Subject: 'Onboarding healthcheck alert',
                Message: JSON.stringify(payload),
                TopicArn: process.env.SNS_TOPIC_ARN,
            }),
        );
        console.log(response);

        return response;
    } catch (error) {
        console.error('Error sending message to Slack');
        throw error;
    }
}

function getMessage(record: SNSEventRecord) {
    const snsMessage = JSON.parse(record.Sns.Message);
    const alarm: string = snsMessage.AlarmName

    type ServiceMap = { name: string, endpoint: string };
    let service: ServiceMap = {
        name: 'Onboarding',
        endpoint: 'https://www.sign-in.service.gov.uk/#'
    }

    console.log(`Getting the message for alarm ${alarm}`);
    let environments = ['Development', 'Build', 'Staging', 'Integration', 'Production'];
    for (let env of environments) {
        if (alarm === `OnboardingSelfService${env}Health`) {
            let service: ServiceMap = {
                name: `Product Pages (${env})`,
                endpoint: ProductPagesEndpoint[env]
            }
        }
        else if (alarm === `OnboardingSelfService${env}Health`) {
            let service: ServiceMap = {
                name: `Self-Service tool (${env})`,
                endpoint: SelfServiceEndpoint[env]
            }
        }
    }

    if (snsMessage.NewStateValue !== 'OK') {
        return {
            Application: "Healthcheck alert",
            Heading: `${service.name}`,
            Message: `*${alarm}* has detected that the service *${service.name}* has stopped working`,
            Colour: 'Red',
            Context: `:govuk: <${service.endpoint}|View page>`
        };
    }

    if (snsMessage.OldStateValue === 'INSUFFICIENT_DATA') {
        return {
            Application: "Healthcheck alert",
            Heading: `${service.name}`,
            Message: `*${alarm}* has detected that the service *${service.name}* is starting up`,
            Colour: 'Yellow',
            Context: `:govuk: <${service.endpoint}|View page>`
        };
    }

    return {
        Application: "Healthcheck alert",
        Heading: `${service.name}`,
        Message: `*${alarm}* has detected that the service *${service.name}* is now running again`,
        Colour: 'Green',
        Context: `:govuk: <${service.endpoint}|View page>`
    };
}
