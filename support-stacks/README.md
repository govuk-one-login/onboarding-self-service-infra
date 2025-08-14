## Deployments

Sign into the account you want to deploy to
export AWS_PROFILE=account-profile
aws sso login

If unsure of account profiles, run aws configure list-profiles

Make sure you have gh installed and have logged in through gh auth login
Note: this github step does not currently work as only an admin can update the github action

And run deploy-support-stacks.sh

Note: merging into main will not automatically deploy changes.