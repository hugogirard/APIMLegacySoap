#!/bin/bash
set -e

# Upload the WSDL file to the storage container
INFRA_DIR="${INFRA_DIR:-infra}"

if [ ! -f params ]; then
	echo "Error: params file not found. Run 'make deploy' first."
	exit 1
fi

RG=$(jq -r '.resourceGroupName.value' params)
STORAGE=$(jq -r '.storageResourceName.value' params)
CONTAINER=$(jq -r '.containerName.value' params)
APIM_GW=$(jq -r '.apimGatewayHostName.value' params | sed 's|https://||')

echo "Uploading WSDL to storage account $STORAGE..."

# Process WSDL template
sed "s/{{domain_name}}/$APIM_GW/g" "$INFRA_DIR/modules/web/service.wsdl" > /tmp/service.wsdl

# Upload to storage
PYTHONWARNINGS=ignore az storage blob upload \
	--account-name "$STORAGE" \
	--container-name "$CONTAINER" \
	--name service.wsdl \
	--file /tmp/service.wsdl \
	--overwrite \
	--auth-mode login

# Clean up
rm -f /tmp/service.wsdl

echo "WSDL upload complete."
