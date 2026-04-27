# PaymentServices.Infrastructure

Bicep templates for deploying the PaymentServices pipeline infrastructure.

## Structure

```
├── modules/
│   ├── functionapp.bicep       ← reusable Function App module
│   ├── appserviceplan.bicep    ← reusable App Service Plan module
│   ├── storageaccount.bicep    ← reusable Storage Account module
│   └── servicebus.bicep        ← Service Bus + all subscriptions
├── dev/
│   └── main.bicep              ← DEV — shared plan, Standard SB
├── qa/
│   └── main.bicep              ← QA — shared plan, Standard SB
└── prod/
    └── main.bicep              ← PROD — dedicated plans, Premium SB
```

## Environment Differences

| Resource | DEV | QA | PROD |
|---|---|---|---|
| App Service Plan | 1 shared EP1 | 1 shared EP1 | 5 dedicated EP1 |
| Min instances | 1 | 1 | 2 |
| Max instances | 5 | 5 | 20 |
| Service Bus | Standard | Standard | Premium |

## Deploying

### Prerequisites
- Azure CLI installed
- Bicep CLI installed (`az bicep install`)
- Logged in to Azure (`az login`)

### DEV
```bash
az deployment group create \
  --resource-group rg-pmtsvc-dev-centralus \
  --template-file dev/main.bicep \
  --parameters \
    appConfigEndpoint=https://appconfig-pmtsvc-dev.azconfig.io \
    appInsightsConnectionString=<connection-string> \
    managedIdentityId=<managed-identity-resource-id> \
    managedIdentityClientId=<managed-identity-client-id>
```

### QA
```bash
az deployment group create \
  --resource-group rg-pmtsvc-qa-centralus \
  --template-file qa/main.bicep \
  --parameters \
    appConfigEndpoint=https://appconfig-pmtsvc-qa.azconfig.io \
    appInsightsConnectionString=<connection-string> \
    managedIdentityId=<managed-identity-resource-id> \
    managedIdentityClientId=<managed-identity-client-id>
```

### PROD
```bash
az deployment group create \
  --resource-group rg-pmtsvc-prod-centralus \
  --template-file prod/main.bicep \
  --parameters \
    appConfigEndpoint=https://appconfig-pmtsvc-prod.azconfig.io \
    appInsightsConnectionString=<connection-string> \
    managedIdentityId=<managed-identity-resource-id> \
    managedIdentityClientId=<managed-identity-client-id>
```

## Resources Created Per Environment

### DEV / QA
- 1 Service Bus namespace (Standard) + payment-processing topic + 5 subscriptions
- 1 App Service Plan (EP1, shared)
- 5 Storage Accounts (one per function app)
- 5 Function Apps

### PROD
- 1 Service Bus namespace (Premium) + payment-processing topic + 5 subscriptions
- 5 App Service Plans (EP1, dedicated per service)
- 5 Storage Accounts
- 5 Function Apps (min 2 instances each)

## What This Repo Does NOT Manage
- Cosmos DB (existing per environment)
- Azure App Configuration (existing per environment)
- Key Vault (existing per environment)
- Application Insights (existing per environment)
- Managed Identity (existing per environment)
- Redis Cache (provision separately)
