# Prerequisites

1. Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
2. Install Bicep:
```Powershell
az bicep install
```
4. Install Azure Functions Core Tools: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local
5. Log in to your AAD tenant and select subscription:
```Powershell
az login --tenant <tenant-id>
az account set --subscription <subscription-id>
```

# Azure infrastructure deployment with Bicep

1. Create a resource group, skip this step if you are using an existing resource group:
```Powershell
az group create --location westeurope --name "<resource-group-name>"
```

2. Run what-if to preview deployment:
```Powershell
az deployment group what-if --resource-group "<resource-group-name>" --template-file ./bicep/main.bicep --parameters ./bicep/parameters_example.json
```

3. Run deployment
```Powershell
az deployment group create --resource-group "<resource-group-name>" --template-file ./bicep/main.bicep --parameters ./bicep/parameters_example.json
```

# Azure Function App deployment with Azure Functions Core Tools

Deploy function app:
```Powershell
cd functionapp
func azure functionapp publish <function-app-name>
```