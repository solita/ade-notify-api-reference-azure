/* -------------------------- */
/* ------- PARAMETERS ------- */
/* -------------------------- */

// Environment name used in resource naming (Azure resource naming restrictions apply)
param env string

// Existing notifier storage account name
param notifierStorageName string

// Existing notifier storage account resource group
param notifierStorageRg string

// Existing source data blob container name
param sourceDataContainerName string

// Existing source data storage account system topic name
param systemTopicName string

// Existing source data storage account system topic resource group
param systemTopicRg string

// Trigger queue name (do not change unless you have modified the notifier deployment)
var triggerQueueName = 'notifier-trigger'


/* ------------------------------------ */
/* - REFERENCES TO EXISTING RESOURCES - */
/* ------------------------------------ */

resource notifierStorage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: notifierStorageName
  scope: resourceGroup(notifierStorageRg)
}

resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' existing = {
  name: systemTopicName
  scope: resourceGroup(systemTopicRg)
}


/* -------------------------- */
/* --- EVENT SUBSCRIPTION --- */
/* -------------------------- */

resource queueEventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2020-10-15-preview' = {
  name: '${systemTopic.name}/${triggerQueueName}-${env}'
  properties: {
    eventDeliverySchema: 'EventGridSchema'
    deliveryWithResourceIdentity: {
      identity: {
        type: 'SystemAssigned'
      }
      destination: {
        endpointType: 'StorageQueue'
        properties: {
          resourceId: notifierStorage.id
          queueName: triggerQueueName
        }
      }
    }
    filter: {
      subjectBeginsWith: '/blobServices/default/containers/${sourceDataContainerName}/blobs/'
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      advancedFilters: [
        {
          key: 'data.ContentLength'
          operatorType: 'NumberGreaterThan'
          value: 0
        }
      ]
    }
  }
}
