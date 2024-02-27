# Self-Service Infrastructure

Infrastructure for deploying and monitoring the self-service applications. Additional documentation inside each component.

## Pre-requisites

To run this project you will need the following:

- [SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) - Used to build and deploy the application
- [Node.js](https://nodejs.org/en/) version 18 - Recommended way to install is via [NVM](https://github.com/nvm-sh/nvm)
- [Docker](https://docs.docker.com/get-docker/) - Required to run SAM locally

### Important

- **Node version 18** is required since the runtimes for Lambda functions are fixed.
