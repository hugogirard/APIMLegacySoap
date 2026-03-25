#!/bin/bash
set -e

# Deploy the SOAP web app using outputs from params
SRC_DIR="${SRC_DIR:-src/BankService}"

if [ ! -f params ]; then
	echo "Error: params file not found. Run 'make deploy' first."
	exit 1
fi

RG=$(jq -r '.resourceGroupName.value' params)
WEBAPP=$(jq -r '.webAppName.value' params)

echo "Deploying SOAP web app to $WEBAPP in resource group $RG..."

# Create zip file
cd "$SRC_DIR" && zip -r ../../app.zip .

# Deploy to Azure Web App
cd ../..
az webapp deploy --resource-group "$RG" --name "$WEBAPP" --src-path app.zip --type zip

# Clean up
rm -f app.zip

echo "Web app deployment complete."
