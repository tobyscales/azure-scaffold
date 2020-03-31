#!/bin/bash
# additional environment variables available: $AZURE_SUBSCRIPTION_ID, $AZURE_AADTENANT_ID and $AZURE_KEYVAULT

echo Location: $AZURE_LOCATION
echo Resource Group: $AZURE_RESOURCE_GROUP

# cribbed from http://fahdshariff.blogspot.com/2014/02/retrying-commands-in-shell-scripts.html
# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run

retry() {
    local -r -i max_attempts="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1
    until $cmd
    do
        if ((attempt_num==max_attempts))
        then
            echo "Attempt $attempt_num failed and there are no more attempts left!"
            return 1
        else
            echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
            sleep $((attempt_num++))
        fi
    done
}

retry 5 az login --identity

az configure --defaults location=$AZURE_LOCATION
az configure --defaults group=$AZURE_RESOURCE_GROUP

cd /$BOOTSTRAP_REPO

### Custom Code goes here 
CONFIG_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/master/"
echo Configurations from: $CONFIG_URL

#TODO -- refactor my Update-Config powershell script into bash, to run in this container
#pwsh -noprofile -nologo -executionpolicy Bypass -File ./scripts/Update-Config.ps1
pwsh

jq -r .solutions config2.json > solutions.json
jq -r .automationModules config2.json > automationModules.json
jq -r .automationVariables config2.json > automationVariables.json
jq -r .automationRunbooks config2.json > runbooks.json
jq -r .automationRunnowbooks config2.json > runnowbooks.json
jq -r .dscConfigs config2.json > dscConfigs.json
jq -r .dscModules config2.json > dscModules.json

az deployment group create --template-file ./templates/Configure_Workspace.json --parameters workspacename=$AZURE_WORKSPACENAME solutions=@solutions.json --no-wait
az deployment group create --template-file ./templates/Configure_AutomationAccount.json --parameters accountname=$AZURE_AUTOMATIONACCOUNT runbooks=@runbooks.json modules=@automationModules.json runnowbooks=@runnowbooks.json variables=@automationVariables.json --no-wait
az deployment group create --template-file ./templates/Configure_DSC.json --parameters accountname=$AZURE_AUTOMATIONACCOUNT configUrl=$CONFIG_URL modules=@dscModules.json configurations=@dscConfigs.json

## from https://docs.microsoft.com/en-us/cli/azure/keyvault/certificate?view=azure-cli-latest#az-keyvault-certificate-create
az keyvault certificate get-default-policy > kvpolicy.json
az keyvault certificate create --vault-name $AZURE_KEYVAULT --name vmcert --policy kvpolicy.json
secrets=$(az keyvault secret list-versions --vault-name vaultname -n cert1 --query "[?attributes.enabled].id" -o tsv)
vm_secrets=$(az vm secret format -s "$secrets")
##TODO: assign to vm at deployment time

## uncomment the below statement to troubleshoot your startup script interactively in ACI (on the Connect tab)
#tail -f /dev/null