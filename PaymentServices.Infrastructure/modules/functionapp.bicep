// =============================================================================
// modules/functionapp.bicep
// Creates a Windows Function App (.NET isolated worker)
// with Managed Identity and App Configuration integration
// =============================================================================

@description('Function App name')
param functionAppName string

@description('Azure region')
param location string

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Storage account name for this function app')
param storageAccountName string

@description('Storage account connection string')
param storageConnectionString string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Azure App Configuration endpoint')
param appConfigEndpoint string

@description('User-assigned managed identity resource ID')
param managedIdentityId string

@description('User-assigned managed identity client ID')
param managedIdentityClientId string

@description('Environment name — DEV, QA, PROD')
param environment string

@description('Resource tags')
param tags object = {}

@description('Additional app settings specific to this function app')
param additionalAppSettings array = []

// -------------------------------------------------------------------------
// Function App
// -------------------------------------------------------------------------
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: union([
        {
          name: 'AzureWebJobsStorage'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'AppConfig:Endpoint'
          value: appConfigEndpoint
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentityClientId
        }
        {
          name: 'AZURE_FUNCTIONS_ENVIRONMENT'
          value: environment
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ], additionalAppSettings)
    }
  }
}

output functionAppName string = functionApp.name
output functionAppId string = functionApp.id
output functionAppHostName string = functionApp.properties.defaultHostName
