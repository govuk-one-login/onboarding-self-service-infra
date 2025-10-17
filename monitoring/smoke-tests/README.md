# Smoke Tests

The smoke tests regularly probe the application endpoints to ensure they are in good health.

The heartbeat check they perform verifies that the application is responding with a 2xx status.

## Deploy

Smoke tests are deployed as two components, the supporting stacks can be deployed with:

```
./scripts/deploy-smoke-tests.sh
```

The canary alarms are contained in a separate stack which can be deployed with:

```
./scripts/deploy-canary-stack.sh
```