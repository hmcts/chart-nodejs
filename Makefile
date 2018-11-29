.DEFAULT_GOAL := all
CHART := nodejs
RELEASE := chart-${CHART}-release
NAMESPACE := chart-tests
TEST := ${RELEASE}-test-service
ACR := hmctssandbox
AKS_RESOURCE_GROUP := cnp-aks-sandbox-rg
AKS_CLUSTER := cnp-aks-sandbox-cluster
TEST_IMAGE_NAME := hmcts/chart-nodejs-testapp
REGISTRY_SANDBOX := hmctssandbox.azurecr.io
REGISTRY_NON_PROD := hmcts.azurecr.io

help:
	@echo ""
	@echo " Available commands:"
	@echo " -------------------"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf " make \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""

all: setup clean lint deploy test ## [ Default command ] Lints, installs and tests the current chart

setup: ## Configures your Azure ACR with sandbox credentials for testing purpose
	az configure --defaults acr=${ACR}
	az acr helm repo add
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER}

clean: ## Removes the installed chart
	-helm delete --purge ${RELEASE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}

lint: ## Lints the chart
	helm lint ${CHART}

deploy: ## Installs the chart with a default image
	helm install ${CHART} --name ${RELEASE} --namespace ${NAMESPACE} --wait --timeout 60

test: ## Tests the installed chart
	helm test ${RELEASE}

test-image: ## Creates a nodejs test image
	@docker build \
		-t ${TEST_IMAGE_NAME} \
		./test-image

push-test-image-sbx: test-image ## Pushes the nodejs test image to the sandbox registry
	az acr login --name ${ACR}
	docker tag ${TEST_IMAGE_NAME} ${REGISTRY_SANDBOX}/${TEST_IMAGE_NAME}
	docker push ${REGISTRY_SANDBOX}/${TEST_IMAGE_NAME}


push-test-image-np: test-image ## Pushes the nodejs test image to the non-prod registry for CI
	docker tag ${TEST_IMAGE_NAME} ${REGISTRY_NON_PROD}/${TEST_IMAGE_NAME}
	docker push ${REGISTRY_NON_PROD}/${TEST_IMAGE_NAME} || @echo you need to be logged in to the ${ACR} acr

tag: ## Creates a git tag with the chart version found in Chart.yaml
	$(eval CHART_VERSION := $(shell sed -n -e 's/version:[ "]*\([^"]*\).*/\1/p' ${CHART}/Chart.yaml))
ifeq ($(shell git rev-parse --abbrev-ref HEAD),"master")
	@echo "You need to be on master to create a tag"
else
	@echo "tagging version $(CHART_VERSION)"
	git tag $(CHART_VERSION)
endif

.PHONY: setup clean lint deploy test all tag test-image push-test-image-sandbox push-test-image-non-prod
