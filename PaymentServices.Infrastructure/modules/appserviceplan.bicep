// =============================================================================
// modules/appserviceplan.bicep
// Creates a Windows App Service Plan (Premium EP1)
// =============================================================================

@description('App Service Plan name')
param planName string

@description('Azure region')
param location string

@description('SKU name — EP1, EP2, EP3 for Premium')
param skuName string = 'EP1'

@description('Minimum number of instances — always warm')
param minimumInstances int = 1

@description('Maximum burst instances')
param maximumInstances int = 10

@description('Resource tags')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: maximumInstances
    reserved: false // Windows
  }
}

output planId string = appServicePlan.id
output planName string = appServicePlan.name
