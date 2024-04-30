# Self-Service Infrastructure

Infrastructure for deploying and monitoring the self-service applications. Additional documentation inside each component.

## Pre-requisites

To run this project you will need the following:

- [aws sso](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html) - Configured to automatically retrieve authentication tokens
- [SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) - Used to build and deploy the application
- [Node.js](https://nodejs.org/en/) version 18 - Recommended way to install is via [NVM](https://github.com/nvm-sh/nvm)

### Important

- **Node version 18** is required since the runtimes for Lambda functions are fixed.

### Structure

Utility scripts that are required by more than one component should be placed in the `/scripts` directory.