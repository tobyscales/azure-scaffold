#!/bin/bash
#comments are PS equivalents

$resourceGroup="devopsmgmt"
$location="South Central US"
$keyVaultName="kv-$resourceGroup"

upn=$(az account show --query user.name --output tsv)
#$upn=(iex "az account show --query user.name --output tsv") //pwsh
userid=$(az ad user show --id $upn --query objectId)
#$userid = (iex "az ad user show --id $upn --query objectId")

az group create --name $resourceGroup --location $location
az keyvault create --resource-group $resourceGroup --name $keyVaultName --enabled-for-deployment true --enabled-for-template-deployment true 
az ad sp create-for-rbac -n "deploy.$resourceGroup" > rbac.json
jq -r '"appId --value \(.appId),tenantId --value \(.tenant),password --value \(.password)"' rbac.json | xargs -t -d, -I {} bash -c 'az keyvault secret set --vault-name $keyVaultName -n {}' 

az group deployment create --resource-group $resourceGroup --template-file ~/code/azuredeploy.json --parameters userObjectId=$userid





#jq -r '"appId --value \(.appId),tenantId --value \(.tenant),password --value \(.password)"' rbac.json | xargs -t -d, -I {} bash -c 'az keyvault secret set --vault-name dnd-azurekv -n {}'
# jq '.appId, .password, .tenant' rbac.json | xargs -I {} -P 3 -t az keyvault secret set --vault-name dnd-azurekv -n "{}" --value "{}" | jq '. | .id' > urls.txt

#// curl https://www.opscode.com/chef/install.sh | sudo bash 

"reference": {
              "keyVault": {
                  "id": "[variables('keyVaultResourceID')]"
              },
              "secretName": "spSecret"
          }
