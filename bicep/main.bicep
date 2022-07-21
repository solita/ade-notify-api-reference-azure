/* -------------------------- */
/* ------- PARAMETERS ------- */
/* -------------------------- */

// Resource naming convention: abbreviation-${app}-${env} (exceptions due to Azure resource naming restrictions)
// Using recommended abbreviations: https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

// App name used in resource naming (Azure resource naming restrictions apply)
param app string

// Environment name used in resource naming (Azure resource naming restrictions apply)
param env string

// Azure region
param location string

// Notify API base url, e.g. 'https://external-api.dev.datahub.s1234567.saas.agiledataengine.com:443/notify-api'
param notifyApiBaseUrl string

// Role id assigned to source data storage account system topic that allows writing messages to notifier trigger queue
// Default value: Storage queue data message sender role id
param roleId string = '/providers/Microsoft.Authorization/roleDefinitions/c6a89b2d-59bc-44d0-9896-0f6e12d7b80a'

// Existing source data storage account system topic name
param systemTopicName string

// Existing source data storage account system topic resource group
param systemTopicRg string

// Virtual network settings
// Change default values if needed
param vnetAddressPrefix string = '10.201.1.0/24'
param subnetAddressPrefix string = '10.201.1.0/28'
param subnetName string = 'functionapp'

// Tags
// Modify according to your policies
param tags object = {
  Application: app
  Environment: env
}


/* -------------------------- */
/* -------- STORAGE --------- */
/* -------------------------- */

// Storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'st${app}${env}'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  location: location
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    isHnsEnabled: false
    networkAcls: {
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
  tags: tags
}

// Container for data source configuration files
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${storageAccount.name}/default/datasource-config'
  properties: {
    publicAccess: 'None'
  }  
}

// Queue for triggering the notifier
resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = {
  name: '${storageAccount.name}/default/notifier-trigger'
}

// Existing source data storage account system topic reference
resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' existing = {
  name: systemTopicName
  scope: resourceGroup(systemTopicRg)
}

// Role assignment for system topic to allow writing messages to the notifier trigger queue
resource systemTopicQueueRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid('${systemTopic.name}${queue.name}')
  properties: {
    roleDefinitionId: roleId
    principalId: systemTopic.identity.principalId
  }
  scope: storageAccount
}


/* -------------------------- */
/* ------- KEY VAULT -------- */
/* -------------------------- */

// Key vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: 'kv-${app}-${env}'
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableSoftDelete: true
    networkAcls: {
      defaultAction: 'Allow'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 14
    tenantId: tenant().tenantId
    accessPolicies: []
  }
}

// Key vault access policy for the function app
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: functionApp.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: tenant().tenantId
      }
    ]
  }
}

// Key vault secret: Notify API key
resource notifyApiKey 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '${keyVault.name}/notify-api-key'
  tags: tags
  properties: {
    value: 'Change this secret in Key Vault after deployment'
  }
}

// Key vault secret: Notify API key secret
resource notifyApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '${keyVault.name}/notify-api-key-secret'
  tags: tags
  properties: {
    value: 'Change this secret in Key Vault after deployment'
  }
}


/* -------------------------- */
/* ------- NETWORKING ------- */
/* -------------------------- */

// Static public IP address (to be allowed in Notify API)
resource ip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'pip-${app}-${env}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  tags: tags
}

// NAT gateway
resource natGateway 'Microsoft.Network/natGateways@2021-08-01' = {
  name: 'ng-${app}-${env}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: ip.id
      }
    ]
  }
  tags: tags
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'vnet-${app}-${env}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          natGateway: {
            id: natGateway.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
  tags: tags
}


/* -------------------------- */
/* ------- FUNCTIONS -------- */
/* -------------------------- */

// Application insights
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'appi-${app}-${env}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: tags
}

// App service plan
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: 'plan-${app}-${env}'
  location: location
  kind: 'linux'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    capacity: 1
  }
  properties: {
    reserved: true
  }
  tags: tags
}

// Function app
resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: 'func-${app}-${env}'
  location: location
  kind: 'functionapp,linux'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    reserved: true
    httpsOnly: true
    serverFarmId: hostingPlan.id
    virtualNetworkSubnetId: resourceId('Microsoft.Network/VirtualNetworks/subnets', vnet.name, subnetName)
    siteConfig: {
      linuxFxVersion: 'python|3.9'
      ftpsState: 'Disabled'
      vnetRouteAllEnabled: true
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsDisableHomepage'
          value: 'true'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'notify_api_base_url'
          value: notifyApiBaseUrl
        }
        {
          name: 'notify_api_key'
          value: '@Microsoft.KeyVault(SecretUri=${notifyApiKey.properties.secretUri})'
        }
        {
          name: 'notify_api_key_secret'
          value: '@Microsoft.KeyVault(SecretUri=${notifyApiKeySecret.properties.secretUri})'
        }
      ]
    }    
  }
}
