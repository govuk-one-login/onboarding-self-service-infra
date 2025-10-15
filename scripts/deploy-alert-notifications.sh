./scripts/deploy-sam-stack.sh \
    --account development \
    --build \
    --stack-name onboarding-infrastructure-monitoring-alert-notifications \
    --base-dir monitoring/alert-notifications \
    --template monitoring/alert-notifications/alert-notifications.template.yml