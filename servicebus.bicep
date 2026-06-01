// =============================================================================
// modules/servicebus.bicep
// Creates a Service Bus namespace with payment-processing topic
// and all required subscriptions.
//
// Flow (Alloy/KYC/TMS removed):
//   Gateway        → AccountResolutionPending   → account-resolution
//   AccountRes     → AccountResolutionCompleted → transfer
//   Transfer       → TransferCompleted/Failed   → rtpsend-outcome
//   (AccountRes failure → AccountResolutionFailed → rtpsend-outcome)
// =============================================================================

@description('Service Bus namespace name')
param namespaceName string

@description('Azure region')
param location string

@description('Service Bus SKU — Standard for DEV/QA, Premium for PROD')
param sku string = 'Standard'

@description('Resource tags')
param tags object = {}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

// -------------------------------------------------------------------------
// Topic: payment-processing
// -------------------------------------------------------------------------
resource paymentTopic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'payment-processing'
  properties: {
    defaultMessageTimeToLive: 'P14D'   // 14 days
    enableBatchedOperations: true
    requiresDuplicateDetection: false
  }
}

// -------------------------------------------------------------------------
// Subscriptions
// -------------------------------------------------------------------------

// account-resolution — entry point of the async pipeline (unchanged)
resource accountResolutionSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: paymentTopic
  name: 'account-resolution'
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    deadLetteringOnFilterEvaluationExceptions: true
  }
}

resource accountResolutionFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = {
  parent: accountResolutionSubscription
  name: 'account-resolution-filter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'state = \'AccountResolutionPending\''
    }
  }
}

// transfer — now triggered by AccountResolution directly (KYC/TMS removed).
// Filter changed: TmsCompleted → AccountResolutionCompleted.
resource transferSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: paymentTopic
  name: 'transfer'
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    deadLetteringOnFilterEvaluationExceptions: true
  }
}

resource transferFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = {
  parent: transferSubscription
  name: 'transfer-filter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'state = \'AccountResolutionCompleted\''
    }
  }
}

// rtpsend-outcome — RTPSend's HandlePaymentOutcome consumes terminal outcomes
// and runs TabaPay (success) or records terminal failure.
resource rtpsendOutcomeSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: paymentTopic
  name: 'rtpsend-outcome'
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    deadLetteringOnFilterEvaluationExceptions: true
  }
}

resource rtpsendOutcomeFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = {
  parent: rtpsendOutcomeSubscription
  name: 'rtpsend-outcome-filter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'state = \'TransferCompleted\' OR state = \'TransferFailed\' OR state = \'AccountResolutionFailed\''
    }
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------
output namespaceName string = serviceBusNamespace.name
output namespaceId string = serviceBusNamespace.id
output connectionString string = listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString
