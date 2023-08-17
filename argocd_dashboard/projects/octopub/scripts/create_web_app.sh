NOW=$(date +%s)
CREATED=${NOW}
RESOURCE_NAME=#{Octopus.Space.Name | Replace "[^A-Za-z0-9]" "-" | ToLower}-#{Octopus.Project.Name | Replace "[^A-Za-z0-9]" "-" | ToLower}-#{Octopus.Environment.Name | Replace "[^A-Za-z0-9]" "-" | ToLower}

# az tag list --resource-id /subscriptions/#{Octopus.Action.Azure.SubscriptionId}/resourcegroups/${RESOURCE_NAME}rg

# Test if the resource group exists
EXISTING_RG=$(az group list --query "[?name=='${RESOURCE_NAME}-rg']")
LENGTH=$(echo ${EXISTING_RG} | jq '. | length')

if [[ $LENGTH == "0" ]]
then
	echo "Creating new resource group"
	echo "##octopus[stdout-verbose]"
	az group create -l westus -n "${RESOURCE_NAME}-rg" --tags LifeTimeInDays=7 Created=${NOW}
	echo "##octopus[stdout-default]"
else
	echo "Resource group already exists"
fi

EXISTING_SP=$(az appservice plan list --resource-group "${RESOURCE_NAME}-rg")
LENGTH=$(echo ${EXISTING_SP} | jq '. | length')
if [[ $LENGTH == "0" ]]
then
	echo "Creating new service plan"
	echo "##octopus[stdout-verbose]"
	az appservice plan create \
      --sku B1 \
      --name "${RESOURCE_NAME}-sp" \
      --resource-group "${RESOURCE_NAME}-rg" \
      --is-linux
  echo "##octopus[stdout-default]"
else
	echo "Service plan already exists"
fi

EXISTING_WA=$(az webapp list --resource-group "${RESOURCE_NAME}-rg")
LENGTH=$(echo ${EXISTING_WA} | jq '. | length')
if [[ $LENGTH == "0" ]]
then
	echo "Creating new web app"
	echo "##octopus[stdout-verbose]"
	az webapp create \
      --resource-group "${RESOURCE_NAME}-rg" \
      --plan "${RESOURCE_NAME}-sp" \
      --name "${RESOURCE_NAME}-wa" \
      --deployment-container-image-name nginx \
      --tags \
      	octopus-environment="#{Octopus.Environment.Name}" \
        octopus-space="#{Octopus.Space.Name}" \
        octopus-project="#{Octopus.Project.Name}" \
        octopus-role="octopub-webapp-cac"
  echo "##octopus[stdout-default]"
else
	echo "Web App already exists"
fi

HOST=$(az webapp list --resource-group "${RESOURCE_NAME}-rg"  --query "[].{hostName: defaultHostName}" | jq -r '.[0].hostName')
set_octopusvariable "HostName" $HOST
write_highlight "[https://$HOST](http://$HOST)"