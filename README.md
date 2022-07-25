# Introduction
This repository contains a reference solution for notifying incoming source data files for Agile Data Engine Notify API (https://ade.document360.io/docs/notify-api) in Azure. The repository is provided for reference purposes only and the solution may require modifications to fit your use case. Please use at your own caution.

# Dependencies
The solution uses the [adenotifier](https://github.com/solita/adenotifier) Python library. Please specify a version in ./functionapp/requirements.txt to prevent issues with library upgrades.

# Architecture
- Image
- Azure Functions premium plan
    - Network, NAT, static public IP
    - Shared premium plan & network for different environments possible to reduce cost if needed

# Deployment
## Prerequisites
### Event Grid System Topic
1. Create an Event Grid system topic for your source data storage account (if one does not exist yet) with one of the options:
    - In the portal: https://docs.microsoft.com/en-us/azure/event-grid/create-view-manage-system-topics
    - With Azure CLI https://docs.microsoft.com/en-us/azure/event-grid/create-view-manage-system-topics-cli
    - With a template, e.g. https://docs.microsoft.com/en-us/azure/event-grid/create-view-manage-system-topics-arm
2. Take note of the system topic name and resource group. These will be needed as Bicep template parameters.

### Deployment tools
1. Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
2. Install Bicep:
```Powershell
az bicep install
```
3. Install Azure Functions Core Tools: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local
4. Log in to your AAD tenant and select subscription:
```Powershell
az login --tenant <tenantid>
az account set --subscription <subscriptionid>
```

## Azure resources
1. Go through the Bicep template and the example parameter values. Format the template according to your needs and policies, set values for parameters.

2. Create a resource group (skip if using an existing resource group):
```Powershell
az group create --location westeurope --name <rgname>
```

3. Run what-if to preview deployment, check output:
```Powershell
az deployment group what-if --resource-group <rgname> --template-file ./bicep/main.bicep --parameters ./bicep/<parameter_file>.json
```

4. Run deployment:
```Powershell
az deployment group create --resource-group <rgname> --template-file ./bicep/main.bicep --parameters ./bicep/<parameter_file>.json
```

## Functions

Deploy function app:
```Powershell
cd functionapp
func azure functionapp publish <appname>
```

# Configuration
## Update Notify API secrets in key vault
The Key Vault secrets are deployed with dummy values and must be updated to the Notify API key and secret. Agile Data Engine support team will provide the secrets:
- notify-api-key
- notify-api-key-secret

Note that you will need to assign a Key Vault access policy that allows secret management to yourself or a security group that you belong to. See [Microsoft documentation](https://docs.microsoft.com/en-us/azure/key-vault/general/assign-access-policy) for detailed instructions.

## Provide the public IP addresses to Agile Data Engine support
Agile Data Engine support needs to add the public IP address to the allowed list before the deployed solution can connect to Notify API. If you have deployed multiple environments, provide IP addresses of each environment to the support team.

## Data source configuration
Configure data sources into a configuration file **datasources.json** and upload it to the deployed storage account to path **datasource-config/datasources.json**. See specifications for the configuration format in the [adenotifier library readme](https://github.com/solita/adenotifier). Additionally configure the following attributes which are used for identifying the data source from incoming BlobCreated events:

| Attribute  | Mandatory | Description |
| --- | --- | --- |
| storage_account  | x | Storage account name of the source file. |
| storage_container  | x | Blob container name of the source file. |
| folder_path  | x | Folder path of the source file. |
| file_extension  | | Optional: File extension of the source file. |

See configuration examples in [config/datasources.json](config/datasources.json).

## Event Grid subscription
To get BlobCreated events from the source data storage account to the notifier queue, an event subscription is needed. You can create an event subscription in Azure Portal, CLI or using a template. More details are available in [Microsoft documentation](https://docs.microsoft.com/en-us/azure/event-grid/event-schema-blob-storage?tabs=event-grid-event-schema).

Use at least the following settings when creating the event subscription:
| Setting  | Value | Notes |
| --- | --- | --- |
| Event schema | Event Grid Schema | - |
| Event types | Blob Created | - |
| Endpoint type | Storage queues | - |
| Managed identity type | System assigned | - |
| Enable subject filtering | true | - |
| Subject begins with | /blobServices/default/containers/<source-data-container-name>/blobs/<optional-path-to-files> | Set <optional-path-to-files> if you do not want events from the entire container. | - |
| Advanced filters: data.ContentLength | > 0 | This prevents duplicate events. |

There is a [Bicep template](config/event_subscription.bicep) and an example [parameter file](config/parameters_example.json) in the **config** folder which can be used to deploy the subscription. Format the template and set the parameters according to your setup.