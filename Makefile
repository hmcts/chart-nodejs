.DEFAULT_GOAL := all
CHART := nodejs
RELEASE := chart-${CHART}-release
NAMESPACE := chart-tests
TEST := ${RELEASE}-${CHART}-test-service
ACR := hmctspublic
ACR_SUBSCRIPTION := DCD-CNP-DEV
AKS_RESOURCE_GROUP := cnp-aks-rg
AKS_CLUSTER := cnp-aks-cluster
TEST_IMAGE_NAME := hmctspubic/chart-nodejs-testapp

help:
	@echo ""
	@echo " Available commands:"
	@echo " -------------------"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf " make \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""

all: setup clean lint deploy test ## [ Default command ] Lints, installs and tests the current chart

setup: ## Configures your Azure ACR with sandbox credentials for testing purpose
	az account set --subscription ${ACR_SUBSCRIPTION}
	az configure --defaults acr=${ACR}
	az acr helm repo add
	az aks get-credentials --overwrite-existing --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER} 

clean: ## Removes the installed chart
	-helm delete ${RELEASE}
	-kubectl delete --namespace ${NAMESPACE} pod/${TEST}

lint: ## Lints the chart
	helm lint ${CHART}

deploy: ## Installs the chart with a default image
	helm install ${CHART} ${RELEASE} --namespace ${NAMESPACE} -f ci-values.yaml --wait --timeout 60s

test: ## Tests the installed chart
	helm test ${RELEASE}

test-image: ## Creates a nodejs test image
	@docker build \
		-t ${TEST_IMAGE_NAME} \
		./test-image

push-test-image: test-image ## Pushes the nodejs test image to the non-prod registry for CI
	az acr login --name ${ACR}
	docker tag ${TEST_IMAGE_NAME} ${ACR}.azurecr.io/${TEST_IMAGE_NAME}
	docker push ${ACR}.azurecr.io/${TEST_IMAGE_NAME} || @echo you need to be logged in to the ${REGISTRY_NON_PROD} acr

tag: ## Creates a git tag with the chart version found in Chart.yaml
	$(eval CHART_VERSION := $(shell sed -n -e 's/version:[ "]*\([^"]*\).*/\1/p' ${CHART}/Chart.yaml))
ifeq ($(shell git rev-parse --abbrev-ref HEAD),"master")
	@echo "You need to be on master to create a tag"
else
	@echo "tagging version $(CHART_VERSION)"
	git tag $(CHART_VERSION)
endif

.PHONY: setup clean lint deploy test all tag test-image push-test-image-sandbox push-test-image-non-prod
