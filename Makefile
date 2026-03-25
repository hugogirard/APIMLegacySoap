# Azure deployment variables (override via environment or command line)
ENVIRONMENT_NAME   ?= legacy-soap-apim
LOCATION           ?= canadacentral
APIM_SKU           ?= Standardv2
PUBLISHER_EMAIL    ?= contoso@noreply.com
PUBLISHER_NAME     ?= Contoso
DEPLOYMENT_NAME    ?= main-$(shell date +%Y%m%d%H%M%S)
INFRA_DIR          := infra

SRC_DIR            := src/BankService

.PHONY: help login validate preview deploy deploy-app destroy show

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

login: ## Login to Azure and set subscription
	az login

preview: ## Run what-if to preview changes
	az deployment sub what-if \
		--name $(DEPLOYMENT_NAME) \
		--location $(LOCATION) \
		--template-file $(INFRA_DIR)/main.bicep \
		--parameters $(INFRA_DIR)/main.bicepparam

deploy: ## Deploy infrastructure via main.bicep and save outputs to params
	az deployment sub create \
		--name $(DEPLOYMENT_NAME) \
		--location $(LOCATION) \
		--template-file $(INFRA_DIR)/main.bicep \
		--parameters $(INFRA_DIR)/main.bicepparam \
		--query properties.outputs -o json > params

show: ## Show the latest deployment outputs
	@cat params

deploy-app: ## Deploy the SOAP web app using outputs from params
	$(eval RG := $(shell jq -r '.resourceGroupName.value' params))
	$(eval WEBAPP := $(shell jq -r '.webAppName.value' params))
	cd $(SRC_DIR) && zip -r ../../app.zip .
	az webapp deploy --resource-group $(RG) --name $(WEBAPP) --src-path app.zip --type zip
	rm -f app.zip

upload-wsdl: ## Upload the WSDL file to the storage container
	$(eval RG := $(shell jq -r '.resourceGroupName.value' params))
	$(eval STORAGE := $(shell jq -r '.storageResourceName.value' params))
	$(eval CONTAINER := $(shell jq -r '.containerName.value' params))
	$(eval APIM_GW := $(shell jq -r '.apimGatewayHostName.value' params | sed 's|https://||'))
	sed 's/{{domain_name}}/$(APIM_GW)/g' $(INFRA_DIR)/modules/web/service.wsdl > /tmp/service.wsdl
	PYTHONWARNINGS=ignore az storage blob upload \
		--account-name $(STORAGE) \
		--container-name $(CONTAINER) \
		--name service.wsdl \
		--file /tmp/service.wsdl \
		--overwrite \
		--auth-mode login
	rm -f /tmp/service.wsdl

destroy: ## Delete the resource group created by the deployment
	az group delete --name rg-$(ENVIRONMENT_NAME) --yes --no-wait
