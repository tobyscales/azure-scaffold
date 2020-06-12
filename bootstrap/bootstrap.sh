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

jq -r .solutions config.json > solutions.json
jq -r .dscConfigs config.json > dscConfigs.json
jq -r .automationVariables config.json > automationVariables.json

touch automationRunbooks.json
touch automationRunnowbooks.json

echo Creating parameters files...

# updates dscModules with actual uri
printf '[\n' >dscModules.json
jq -M -r '.dscModules[] | .name, .location' config.json | while read -r name; read -r location; do
 if [ "${location,,}" = "psgallery" ]; then
  echo "Retrieving $name..."
  uri="$(curl -sD - -o -L https://www.powershellgallery.com/api/v2/package/$name | awk '/location/ {print $2}' | tr -d '\r')"
  printf '  {\n    "name": "%s",\n"uri": "%s"\n  },\n' "$name" "$uri" >>dscModules.json
 fi
done
sed -i '$ s/.$/\n]/' dscModules.json

# updates automationModules with description, type and actual uri
printf '[\n' >automationModules.json
jq -M -r '.automationModules[] | .name, .location' config.json | while read -r name; read -r location; do
  echo "Retrieving $name..."
  type="$(curl -s -L "https://www.powershellgallery.com/api/v2/FindPackagesById?id='$name'" | grep -m 1 -oiE '<d:ItemType>(.*?)</d:ItemType>' | sed -e 's,.*<d:ItemType>\([^<]*\)</d:ItemType>.*,\1,g' | head -n1)"
  description="$(curl -s -L "https://www.powershellgallery.com/api/v2/FindPackagesById?id='$name'" | grep -m 1 -oiE '<d:Description>(.*?)</d:Description>' | sed -e 's,.*<d:Description>\([^<]*\)</d:Description>.*,\1,g' | head -n1)"
  uri="$(curl -sD - -o -L https://www.powershellgallery.com/api/v2/package/$name | awk '/location/ {print $2}' | tr -d '\r')"
 printf '  {\n    "name": "%s",\n"uri": "%s",\n"type": "%s",\n"description": "%s"\n  },\n' "$name" "$uri" "$type" "$description" >>automationModules.json
done
sed -i '$ s/.$/\n]/' automationModules.json

# updates automationRunbooks with type and actual uri

##TODO: fixup the $type deployment for automationrunbooks
printf '[\n' >automationRunbooks.json
printf '[\n' >automationRunnowbooks.json
jq -M -r '.automationRunbooks[] | .name, .location, .run' config.json | while read -r name; read -r location; read -r run; do
  echo "Retrieving $name..."
  type="$(curl -s -L "https://www.powershellgallery.com/api/v2/FindPackagesById?id='$name'" | grep -m 1 -oiE '<d:ItemType>(.*?)</d:ItemType>' | sed -e 's,.*<d:ItemType>\([^<]*\)</d:ItemType>.*,\1,g' | head -n1)"
  description="$(curl -s -L "https://www.powershellgallery.com/api/v2/FindPackagesById?id='$name'" | grep -m 1 -oiE '<d:Description>(.*?)</d:Description>' | sed -e 's,.*<d:Description>\([^<]*\)</d:Description>.*,\1,g' | head -n1)"
  uri="$(curl -sD - -o -L https://www.powershellgallery.com/api/v2/package/$name | awk '/location/ {print $2}' | tr -d '\r')"
  if [ "${run,,}" = "now" ]; then
   printf '  {\n    "name": "%s",\n"uri": "%s",\n"runbookType": "%s",\n"description": "%s"\n  },\n' "$name" "$uri" "$type" "$description" >>automationRunnowbooks.json
  else
   printf '  {\n    "name": "%s",\n"uri": "%s",\n"runbookType": "%s",\n"description": "%s"\n  },\n' "$name" "$uri" "$type" "$description" >>automationRunbooks.json
  fi
done
sed -i '$ s/.$/\n]/' automationRunbooks.json
sed -i '$ s/.$/\n]/' automationRunnowbooks.json

echo Finished updating files.
# xargs -I '{}' curl -sD - -o -L https://www.powershellgallery.com/api/v2/package/'{}' | awk '/location/ {print $2}'
# jq -r '.dscModules[].name' config.json | xargs -I '{}' curl -sD - -o -L https://www.powershellgallery.com/api/v2/package/'{}' | awk '/location/ {print $2}'
# jq -r '.automationModules[].name' config.json | xargs -I '{}' curl -sD - -o -L https://www.powershellgallery.com/api/v2/package/'{}' | awk '/location/ {print $2}'
# jq -r '.automationRunBooks[].name' config.json | xargs -I '{}' curl -sD - -o -L https://www.powershellgallery.com/api/v2/package/'{}' | awk '/location/ {print $2}'

#TODO: the variables file doesn't seem to be working (invalid JSON value: value)
echo Running deployments...
az deployment group create --resource-group $AZURE_RESOURCE_GROUP --template-file ./templates/Configure_Workspace.json --parameters workspacename=$AZURE_WORKSPACENAME solutions=@solutions.json --no-wait
az deployment group create --resource-group $AZURE_RESOURCE_GROUP --template-file ./templates/Configure_AutomationAccount.json --parameters accountname=$AZURE_AUTOMATIONACCOUNT runbooks=@automationRunbooks.json modules=@automationModules.json runnowbooks=@automationRunnowbooks.json variables=@automationVariables.json --no-wait
az deployment group create --resource-group $AZURE_RESOURCE_GROUP --template-file ./templates/Configure_DSC.json --parameters accountname=$AZURE_AUTOMATIONACCOUNT configUrl=$CONFIG_URL modules=@dscModules.json configurations=@dscConfigs.json

##TODO: assign to vm at deployment time
## from https://docs.microsoft.com/en-us/cli/azure/keyvault/certificate?view=azure-cli-latest#az-keyvault-certificate-create
#az keyvault certificate get-default-policy > kvpolicy.json
#az keyvault certificate create --vault-name $AZURE_KEYVAULT --name vmcert --policy kvpolicy.json
#secrets=$(az keyvault secret list-versions --vault-name vaultname -n cert1 --query "[?attributes.enabled].id" -o tsv)
#vm_secrets=$(az vm secret format -s "$secrets")

## uncomment the below statement to troubleshoot your startup script interactively in ACI (on the Connect tab)
#tail -f /dev/null