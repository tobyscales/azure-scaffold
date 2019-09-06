#!/bin/bash
#comments are PS equivalents

keyVaultName="kv-$AZURE_RESOURCE_GROUP"

echo location: $AZURE_LOCATION
echo Resourcegroup: $AZURE_RESOURCE_GROUP

az login --identity
az configure --defaults location="$AZURE_LOCATION"
az configure --defaults group="$AZURE_RESOURCE_GROUP"

#group=$resourceGroup

#upn=$(az account show --query user.name --output tsv)
#$upn=(iex "az account show --query user.name --output tsv") //pwsh
#userid=$(az ad user show --id $upn --query objectId)
#$userid = (iex "az ad user show --id $upn --query objectId")

az group create
#--name $resourceGroup --location $location
#az keyvault create --resource-group $resourceGroup --name $keyVaultName --enabled-for-deployment true --enabled-for-template-deployment true 
#az ad sp create-for-rbac -n "deploy.$resourceGroup" > rbac.json
#jq -r '"appId --value \(.appId),tenantId --value \(.tenant),password --value \(.password)"' rbac.json | xargs -t -d, -I {} bash -c 'az keyvault secret set --vault-name $keyVaultName -n {}' 

#az group deployment create --resource-group $resourceGroup --template-file ~/code/azuredeploy.json --parameters userObjectId=$userid

#                "chmod +x /code/$GITHUB_REPO/bootstrap/bootstrap.sh; /code/$GITHUB_REPO/bootstrap/bootstrap.sh"


#jq -r '"appId --value \(.appId),tenantId --value \(.tenant),password --value \(.password)"' rbac.json | xargs -t -d, -I {} bash -c 'az keyvault secret set --vault-name dnd-azurekv -n {}'
# jq '.appId, .password, .tenant' rbac.json | xargs -I {} -P 3 -t az keyvault secret set --vault-name dnd-azurekv -n "{}" --value "{}" | jq '. | .id' > urls.txt

#// curl https://www.opscode.com/chef/install.sh | sudo bash 

#"reference": {
#              "keyVault": {
#                  "id": "[variables('keyVaultResourceID')]"
#              },
#              "secretName": "spSecret"
#          }
