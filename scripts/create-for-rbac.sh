
$userid = (Get-AzADUser -DisplayName "{name}").id

upn=$(az account show --query user.name --output tsv) //bash
$upn=(iex "az account show --query user.name --output tsv") //pwsh
$userid = (iex "az ad user show --upn-or-object-id $upn --query objectId")

az group create --name ExampleGroup --location "West US"
az group deployment create --resource-group ExampleGroup --template-file rbac-rg.json --parameters userObjectId=$userid

az ad sp create-for-rbac -n 
jq -r '"appId --value \(.appId),tenantId --value \(.tenant),password --value \(.password)"' rbac.json | xargs -t -d, -I {} bash -c 'az keyvault secret set --vault-name dnd-azurekv -n {}'


// jq '.appId, .password, .tenant' rbac.json | xargs -I {} -P 3 -t az keyvault secret set --vault-name dnd-azurekv -n "{}" --value "{}" | jq '. | .id' > urls.txt
// jq -r '"appId --value \(.appId),tenantId --value \(.tenant),password --value \(.password)"' rbac.json | xargs -t -d, -I {} bash -c 'az keyvault secret set --vault-name dnd-azurekv -n {}' 
// curl https://www.opscode.com/chef/install.sh | sudo bash 

"reference": {
              "keyVault": {
                  "id": "[variables('keyVaultResourceID')]"
              },
              "secretName": "spSecret"
          }
