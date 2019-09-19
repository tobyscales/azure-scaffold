#!/bin/bash
# additional environment variables available: $AZURE_SUBSCRIPTION_ID, $AZURE_AADTENANT_ID and $AZURE_KEYVAULT
echo Location: $AZURE_LOCATION
echo Resource Group: $AZURE_RESOURCE_GROUP

az login --identity
az configure --defaults location=$AZURE_LOCATION
az configure --defaults group=$AZURE_RESOURCE_GROUP

cd /code

## from https://docs.microsoft.com/en-us/cli/azure/keyvault/certificate?view=azure-cli-latest#az-keyvault-certificate-create
az keyvault certificate create --vault-name $AZURE_KEYVAULT --name $AZURE_RESOURCE_GROUP --policy "$(az keyvault certificate get-default-policy)"
secrets=$(az keyvault secret list-versions --vault-name vaultname -n cert1 --query "[?attributes.enabled].id" -o tsv)
vm_secrets=$(az vm secret format -s "$secrets")
##TODO: assign to vm at deployment time

jq -r '\(.dscConfigs)' config2.json > dscConfigs.json
jq -r '\(.dscModules)' config2.json > dscModules.json

az group deployment create --template-file ./templates/dsc/azuredeploy.json --parameters accountname=$AZURE_AUTOMATIONACCOUNT configurations=@dscConfigs.json modules=@dscModules.json
## sample keyvault secret set/get operations
az keyvault secret set --vault-name $AZURE_KEYVAULT --name "mySecret" --value "mySecretValue"  > secret.json
jq -r '"secretUrl: \(.id)"' secret.json

az keyvault secret show --vault-name $AZURE_KEYVAULT --name "mySecret" > value.json
jq -r '"secretValue: \(.value)"' value.json

## uncomment the below statement to troubleshoot your startup script interactively in ACI (on the Connect tab)
tail -f /dev/null