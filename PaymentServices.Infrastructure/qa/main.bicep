// =============================================================================
// qa/main.bicep
// QA Environment — shared App Service Plan, Standard Service Bus
// All 5 function apps share one EP1 plan
// =============================================================================

@description('QA environment name')
param environment string = 'qa'

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
// Service Bus — Standard tier for QA
// -------------------------------------------------------------------------
module serviceBus '../modules/servicebus.bicep' = {
  name: 'servicebus-${environment}'
  params: {
    namespaceName: 'sb-${prefix}-${environment}-${location}'
    location: location
    sku: 'Standard'
    tags: tags
  }
}

// -------------------------------------------------------------------------
// Shared App Service Plan — EP1
// -------------------------------------------------------------------------
module appServicePlan '../modules/appserviceplan.bicep' = {
  name: 'appserviceplan-${environment}'
  params: {
    planName: 'appcs-${prefix}-${environment}-${location}'
    location: location
    skuName: 'EP1'
    minimumInstances: 1
    maximumInstances: 5
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

module storageCompliance '../modules/storageaccount.bicep' = {
  name: 'storage-compliance-${environment}'
  params: {
    storageAccountName: 'st${prefix}compliance${environment}'
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

module storageEventNotification '../modules/storageaccount.bicep' = {
  name: 'storage-evtnotif-${environment}'
  params: {
    storageAccountName: 'st${prefix}evtnotif${environment}'
    location: location
    tags: tags
  }
}

// -------------------------------------------------------------------------
// Function Apps
// -------------------------------------------------------------------------
module gatewayFunctionApp '../modules/functionapp.bicep' = {
  name: 'fa-gateway-${environment}'
  params: {
    functionAppName: 'fa-${prefix}-gateway-${environment}-${location}'
    location: location
    appServicePlanId: appServicePlan.outputs.planId
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
    appServicePlanId: appServicePlan.outputs.planId
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

module complianceFunctionApp '../modules/functionapp.bicep' = {
  name: 'fa-compliance-${environment}'
  params: {
    functionAppName: 'fa-${prefix}-compliance-${environment}-${location}'
    location: location
    appServicePlanId: appServicePlan.outputs.planId
    storageAccountName: storageCompliance.outputs.storageAccountName
    storageConnectionString: storageCompliance.outputs.connectionString
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
    appServicePlanId: appServicePlan.outputs.planId
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

module eventNotificationFunctionApp '../modules/functionapp.bicep' = {
  name: 'fa-evtnotif-${environment}'
  params: {
    functionAppName: 'fa-${prefix}-evtnotif-${environment}-${location}'
    location: location
    appServicePlanId: appServicePlan.outputs.planId
    storageAccountName: storageEventNotification.outputs.storageAccountName
    storageConnectionString: storageEventNotification.outputs.connectionString
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
output complianceFunctionAppName string = complianceFunctionApp.outputs.functionAppName
output transferFunctionAppName string = transferFunctionApp.outputs.functionAppName
output eventNotificationFunctionAppName string = eventNotificationFunctionApp.outputs.functionAppName
