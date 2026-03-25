#!/bin/bash
set -e

# Deploy infrastructure via main.bicep and save outputs to params
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-main-$(date +%Y%m%d%H%M%S)}"
LOCATION="${LOCATION:-canadacentral}"
INFRA_DIR="${INFRA_DIR:-infra}"

echo "Deploying infrastructure..."
az deployment sub create \
	--name "$DEPLOYMENT_NAME" \
	--location "$LOCATION" \
	--template-file "$INFRA_DIR/main.bicep" \
	--parameters "$INFRA_DIR/main.bicepparam" \
	--query properties.outputs -o json > params

echo "Deployment complete. Outputs saved to params file."
