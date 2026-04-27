// =============================================================================
// modules/servicebus.bicep
// Creates a Service Bus namespace with payment-processing topic
// and all required subscriptions
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

resource kycCheckSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: paymentTopic
  name: 'kyc-check'
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    deadLetteringOnFilterEvaluationExceptions: true
  }
}

resource kycCheckFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = {
  parent: kycCheckSubscription
  name: 'kyc-check-filter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'state = \'KycPending\''
    }
  }
}

resource tmsCheckSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: paymentTopic
  name: 'tms-check'
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    deadLetteringOnFilterEvaluationExceptions: true
  }
}

resource tmsCheckFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = {
  parent: tmsCheckSubscription
  name: 'tms-check-filter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'state = \'TmsPending\''
    }
  }
}

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
      sqlExpression: 'state = \'TmsCompleted\''
    }
  }
}

resource eventNotificationSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: paymentTopic
  name: 'event-notification'
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    deadLetteringOnFilterEvaluationExceptions: true
  }
}

resource eventNotificationFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = {
  parent: eventNotificationSubscription
  name: 'event-notification-filter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'state = \'TransferCompleted\' OR state = \'TransferFailed\' OR state = \'AccountResolutionFailed\' OR state = \'KycFailed\' OR state = \'KycManualReview\' OR state = \'TmsCompleted\' OR state = \'TmsComplianceAlert\' OR state = \'TmsFailed\''
    }
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------
output namespaceName string = serviceBusNamespace.name
output namespaceId string = serviceBusNamespace.id
output connectionString string = listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString
