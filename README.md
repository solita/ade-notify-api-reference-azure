# Introduction
This repository contains a reference solution for notifying incoming source data files for Agile Data Engine Notify API (https://ade.document360.io/docs/notify-api) in Azure. The repository is provided for reference purposes only and the solution may require modifications to fit your use case. Please use at your own caution.

# Dependencies
The solution uses the [adenotifier](https://github.com/solita/adenotifier) Python library. Please specify a version in ./functionapp/requirements.txt to prevent issues with library upgrades.

# Architecture
- Image
- Azure Functions premium plan
    - Network, NAT, static public IP

# Deployment
## Prerequisites
### Event Grid System Topic
1. Create an Event Grid system topic for your source data storage account (if one does not exist yet) with one of the options:
    * In the portal: https://docs.microsoft.com/en-us/azure/event-grid/create-view-manage-system-topics
    * With Azure CLI https://docs.microsoft.com/en-us/azure/event-grid/create-view-manage-system-topics-cli
    * With a template, e.g. https://docs.microsoft.com/en-us/azure/event-grid/create-view-manage-system-topics-arm
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

- Set Notify API key & secret to Key Vault
- Provide private IP to Agile Data Engine support
- Configure data sources in the configuration file "datasources.json", place file in path datasource-config/datasources.json
- Create an event subscription for the system topic
    - Bicep example

# Testing
...