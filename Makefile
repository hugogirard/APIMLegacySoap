# Azure deployment variables (override via environment or command line)
ENVIRONMENT_NAME   ?= legacy-soap-apim
LOCATION           ?= canadacentral
APIM_SKU           ?= Standardv2
PUBLISHER_EMAIL    ?= contoso@noreply.com
PUBLISHER_NAME     ?= Contoso
DEPLOYMENT_NAME    ?= main-$(shell date +%Y%m%d%H%M%S)
INFRA_DIR          := infra

SRC_DIR            := src/BankService
SCRIPTS_DIR        := scripts

.PHONY: help login validate preview deploy deploy-app upload-wsdl deploy-all destroy show

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

login: ## Login to Azure and set subscription
	az login

deploy-all: ## Deploy infrastructure, upload WSDL, and deploy app (full deployment)
	@DEPLOYMENT_NAME=$(DEPLOYMENT_NAME) LOCATION=$(LOCATION) INFRA_DIR=$(INFRA_DIR) SRC_DIR=$(SRC_DIR) $(SCRIPTS_DIR)/deploy-all.sh

deploy: ## Deploy infrastructure via main.bicep and save outputs to params
	@DEPLOYMENT_NAME=$(DEPLOYMENT_NAME) LOCATION=$(LOCATION) INFRA_DIR=$(INFRA_DIR) $(SCRIPTS_DIR)/deploy.sh

show: ## Show the latest deployment outputs
	@cat params

deploy-app: ## Deploy the SOAP web app using outputs from params
	@SRC_DIR=$(SRC_DIR) $(SCRIPTS_DIR)/deploy-app.sh

upload-wsdl: ## Upload the WSDL file to the storage container
	@INFRA_DIR=$(INFRA_DIR) $(SCRIPTS_DIR)/upload-wsdl.sh

destroy: ## Delete the resource group created by the deployment
	az group delete --name rg-$(ENVIRONMENT_NAME) --yes --no-wait
