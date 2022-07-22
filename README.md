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

1. Create a resource group, skip this step if you are using an existing resource group:
```Powershell
az group create --location westeurope --name <rgname>
```

2. Run what-if to preview deployment:
```Powershell
az deployment group what-if --resource-group <rgname> --template-file ./bicep/main.bicep --parameters ./bicep/parameters_example.json
```

3. Run deployment:
```Powershell
az deployment group create --resource-group <rgname> --template-file ./bicep/main.bicep --parameters ./bicep/parameters_example.json
```

## Functions

Deploy function app:
```Powershell
cd functionapp
func azure functionapp publish <appname>
```

# Configuration

In progress...

- Set Notify API key & secret to Key Vault
- Provide private IP to Agile Data Engine support
- Configure data sources in the configuration file "datasources.json"
- Create an event subscription for the system topic
    - Bicep example

# Testing
- Test file
- ADE instructions
