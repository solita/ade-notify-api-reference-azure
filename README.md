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

3. Run deployment
```Powershell
az deployment group create --resource-group <rgname> --template-file ./bicep/main.bicep --parameters ./bicep/parameters_example.json
```

## Functions

Deploy function app:
```Powershell
cd functionapp
func azure functionapp publish <appname>
```