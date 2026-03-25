#!/bin/bash
set -e

# Deploy all: infrastructure, upload WSDL, and deploy app
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo "=== Starting full deployment ==="
echo ""

echo "Step 1/3: Deploying infrastructure..."
"$SCRIPT_DIR/deploy.sh"
echo ""

echo "Step 2/3: Uploading WSDL..."
"$SCRIPT_DIR/upload-wsdl.sh"
echo ""

echo "Step 3/3: Deploying application..."
"$SCRIPT_DIR/deploy-app.sh"
echo ""

echo "=== Full deployment complete! ==="
