// =============================================================================
// prod/main.bicep
// PROD Environment — dedicated App Service Plans per service
// Premium Service Bus, min 2 instances per function app
// =============================================================================

@description('PROD environment name')
param environment string = 'prod'

@description('Azure region')
param location string = 'centralus'

@description('Existing App Configuration endpoint')
param appConfigEndpoint string

@description('Existing Application Insights connection string')
param appInsightsConnectionString string

@description('Existing user-assigned managed identity resource ID')
param managedIdentityId string

@description('Existing user-assigned managed identity client ID')
param managedIdentityClientId string

var prefix = 'pmtsvc'
var tags = {
  Environment: toUpper(environment)
  Train: 'Digital'
  Team: 'Services'
}

// -------------------------------------------------------------------------
// Service Bus — Premium tier for PROD
// -------------------------------------------------------------------------
module serviceBus '../modules/servicebus.bicep' = {
  name: 'servicebus-${environment}'
  params: {
    namespaceName: 'sb-${prefix}-${environment}-${location}'
    location: location
    sku: 'Premium'
    tags: tags
  }
}

// -------------------------------------------------------------------------
// Dedicated App Service Plans — one per service for independent scaling
// -------------------------------------------------------------------------
module planGateway '../modules/appserviceplan.bicep' = {
  name: 'plan-gateway-${environment}'
  params: {
    planName: 'appcs-${prefix}-gateway-${environment}-${location}'
    location: location
    skuName: 'EP1'
    minimumInstances: 2
    maximumInstances: 20
    tags: tags
  }
}

module planAccountResolution '../modules/appserviceplan.bicep' = {
  name: 'plan-acctres-${environment}'
  params: {
    planName: 'appcs-${prefix}-acctres-${environment}-${location}'
    location: location
    skuName: 'EP1'
    minimumInstances: 2
    maximumInstances: 20
    tags: tags
  }
}

module planTransfer '../modules/appserviceplan.bicep' = {
  name: 'plan-transfer-${environment}'
  params: {
    planName: 'appcs-${prefix}-transfer-${environment}-${location}'
    location: location
    skuName: 'EP1'
    minimumInstances: 2
    maximumInstances: 20
    tags: tags
  }
}

// -------------------------------------------------------------------------
// Storage Accounts
// -------------------------------------------------------------------------
module storageGateway '../modules/storageaccount.bicep' = {
  name: 'storage-gateway-${environment}'
  params: {
    storageAccountName: 'st${prefix}gateway${environment}'
    location: location
    tags: tags
  }
}

module storageAccountResolution '../modules/storageaccount.bicep' = {
  name: 'storage-acctres-${environment}'
  params: {
    storageAccountName: 'st${prefix}acctres${environment}'
    location: location
    tags: tags
  }
}

module storageTransfer '../modules/storageaccount.bicep' = {
  name: 'storage-transfer-${environment}'
  params: {
    storageAccountName: 'st${prefix}transfer${environment}'
    location: location
    tags: tags
  }
}

// -------------------------------------------------------------------------
// Function Apps — each on its own dedicated plan
// -------------------------------------------------------------------------
module gatewayFunctionApp '../modules/functionapp.bicep' = {
  name: 'fa-gateway-${environment}'
  params: {
    functionAppName: 'fa-${prefix}-gateway-${environment}-${location}'
    location: location
    appServicePlanId: planGateway.outputs.planId
    storageAccountName: storageGateway.outputs.storageAccountName
    storageConnectionString: storageGateway.outputs.connectionString
    appInsightsConnectionString: appInsightsConnectionString
    appConfigEndpoint: appConfigEndpoint
    managedIdentityId: managedIdentityId
    managedIdentityClientId: managedIdentityClientId
    environment: toUpper(environment)
    tags: tags
  }
}

module accountResolutionFunctionApp '../modules/functionapp.bicep' = {
  name: 'fa-acctres-${environment}'
  params: {
    functionAppName: 'fa-${prefix}-acctres-${environment}-${location}'
    location: location
    appServicePlanId: planAccountResolution.outputs.planId
    storageAccountName: storageAccountResolution.outputs.storageAccountName
    storageConnectionString: storageAccountResolution.outputs.connectionString
    appInsightsConnectionString: appInsightsConnectionString
    appConfigEndpoint: appConfigEndpoint
    managedIdentityId: managedIdentityId
    managedIdentityClientId: managedIdentityClientId
    environment: toUpper(environment)
    tags: tags
  }
}

module transferFunctionApp '../modules/functionapp.bicep' = {
  name: 'fa-transfer-${environment}'
  params: {
    functionAppName: 'fa-${prefix}-transfer-${environment}-${location}'
    location: location
    appServicePlanId: planTransfer.outputs.planId
    storageAccountName: storageTransfer.outputs.storageAccountName
    storageConnectionString: storageTransfer.outputs.connectionString
    appInsightsConnectionString: appInsightsConnectionString
    appConfigEndpoint: appConfigEndpoint
    managedIdentityId: managedIdentityId
    managedIdentityClientId: managedIdentityClientId
    environment: toUpper(environment)
    tags: tags
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------
output serviceBusConnectionString string = serviceBus.outputs.connectionString
output gatewayFunctionAppName string = gatewayFunctionApp.outputs.functionAppName
output accountResolutionFunctionAppName string = accountResolutionFunctionApp.outputs.functionAppName
output transferFunctionAppName string = transferFunctionApp.outputs.functionAppName
