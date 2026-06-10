# Deploying the sign-in.service.gov.uk domain 

The script here is  used to deploy the sign-in.service.gov.uk hosted zone and it's relevant subdomains. It also deploys the resources for the `admin` subdomain and SES identity

## Usage

```sh
./deploy.sh <ENV>

```

where ENV is one of `dev` OR `development`, `build`, `staging`, `integration`, `production`. This will use the relevant parameters file in `/config/<ENV>/parameters.json` to deploy the domains template.

