# Self-Service Infrastructure

Infrastructure for deploying and monitoring the self-service applications. Additional documentation inside each component.

## Pre-requisites

To run this project you will need the following:

- [SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) - Used to build and deploy the application
- [Node.js](https://nodejs.org/en/) version 18 - Recommended way to install is via [NVM](https://github.com/nvm-sh/nvm)

### Important

- **Node version 18** is required since the runtimes for Lambda functions are fixed.

### Structure

All orchestration components should live within their own directory within one of these parent directories:

- `/containers` - for a docker images
- `/infrastructure` - for general infrastructure components
- `/monitoring` - for any components related to observability and monitoring
- `/pipelines` - for all stacks that describe a secure deployment pipeline

The stack name prefix for these components should be consistent across all these categories. 

Utility scripts should be placed in the `/scripts` directory.