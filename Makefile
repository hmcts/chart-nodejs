.DEFAULT_GOAL := all
CHART := nodejs
RELEASE := chart-${CHART}-release
NAMESPACE := chart-tests
TEST := ${RELEASE}-test-service
ACR := hmctssandbox
AKS_RESOURCE_GROUP := cnp-aks-sandbox-rg
AKS_CLUSTER := cnp-aks-sandbox-cluster

setup:
	az configure --defaults acr=${ACR}
	az acr helm repo add
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER}

clean:
	-helm delete --purge ${RELEASE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}

lint:
	helm lint ${CHART}

deploy:
	helm install ${CHART} --name ${RELEASE} --namespace ${NAMESPACE} --wait --timeout 60

test:
	helm test ${RELEASE}

all: setup clean lint deploy test

tag:
	$(eval CHART_VERSION := $(shell sed -n -e 's/version:[ "]*\([^"]*\).*/\1/p' ${CHART}/Chart.yaml))
ifeq ($(shell git rev-parse --abbrev-ref HEAD),"master")
	@echo "You need to be on master to create a tag"
else
	@echo "tagging version $(CHART_VERSION)"
	git tag $(CHART_VERSION)
endif

.PHONY: setup clean lint deploy test all tag
