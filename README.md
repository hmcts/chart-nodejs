# chart-nodejs

[![Build Status](https://dev.azure.com/hmcts/CNP/_apis/build/status/Helm%20Charts/chart-nodejs)](https://dev.azure.com/hmcts/CNP/_build/latest?definitionId=66)

Nodejs Applications Helm chart.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

Note: /health/readiness and /health/liveness exposed by [nodejs-healthcheck](https://github.com/hmcts/nodejs-healthcheck) are used for readiness and liveness checks.

This chart adds below templates from [chart-library](https://github.com/hmcts/chart-library/) based on the chosen configuration:

- [Deployment](https://github.com/hmcts/chart-library/tree/master#deployment)
- [Key Vault Secrets](https://github.com/hmcts/chart-library#keyvault-secret-csi-volumes)
- [Horizontal Pod Auto Scaler](https://github.com/hmcts/chart-library/tree/master#hpa-horizontal-pod-auto-scaler)
- [Ingress](https://github.com/hmcts/chart-library/tree/master#ingress)
- [Pod Disruption Budget](https://github.com/hmcts/chart-library/tree/master#pod-disruption-budget)
- [Service](https://github.com/hmcts/chart-library/tree/master#service)
- [Deployment Tests](https://github.com/hmcts/chart-library/tree/master#smoke-and-functional-tests)

## Example configuration

```yaml
nodejs: 
  applicationPort: 8080
  image: ${IMAGE}
  secrets: 
    ENVIRONMENT_VAR:
        secretRef: some-secret-reference
        key: connectionString
    ENVIRONMENT_VAR_OTHER:
        secretRef: some-secret-reference-other
        key: connectionStringOther
        disabled: true #ENVIRONMENT_VAR_OTHER will not be set to environment
  environment:
    REFORM_TEAM: cnp
    REFORM_SERVICE_NAME: rhubarb-frontend
    REFORM_ENVIRONMENT: preview
    ROOT_APPENDER: CNP
  configmap:
    VAR_A: VALUE_A
    VAR_B: VALUE_B  
  keyVaults:
    cmc:
      secrets:
        - smoke-test-citizen-username
        - smoke-test-ushmmer-password
    s2s:
      secrets:
        - microservicekey-cmcLegalFrontend
  applicationInsightsInstrumentKey: some-key
```

## Startup probes
Startup probes are defined in the [library template](https://github.com/hmcts/chart-library/tree/dtspo-2201-startup-probes#startup-probes) and should be configured for slow starting applications.
The default values below (defined in the chart) should be sufficient for most applications but can be overriden as required.
```yaml
startupPath: '/health/liveness'
startupDelay: 5
startupTimeout: 3
startupPeriod: 10
startupFailureThreshold: 3
```

To configure startup probes for a slow starting application:  
- Set the value of `(startupFailureThreshold x startupPeriodSeconds)` to cover the longest startup time required by the application
- If `livenessDelay` is currently configured, set the value to `0`  

### Example configuration
The below example will allow the application 360 seconds to complete startup.  
```yaml
nodejs:
  livenessDelay: 0
  startupPeriod: 120
  startupFailureThreshold: 3
```
Also see example [pull request](https://github.com/hmcts/cnp-flux-config/pull/12922/files).


### HPA Horizontal Pod Autoscaler
To adjust the number of pods in a deployment depending on CPU utilization AKS supports horizontal pod autoscaling.
To enable horizontal pod autoscaling you can enable the autoscaling section. 
https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-scale#autoscale-pods

```yaml
autoscaling:        # Default is false
  enabled: true 
  maxReplicas: 5    # Required setting
  targetCPUUtilizationPercentage: 80 # Default is 80% target CPU utilization
```

## Development and Testing

Default configuration (e.g. default image and ingress host) is setup for sandbox. This is suitable for local development and testing.

- Ensure you have logged in with `az cli` and are using `sandbox` subscription (use `az account show` to display the current one).
- For local development see the `Makefile` for available targets.
- To execute an end-to-end build, deploy and test run `make`.
- to clean up deployed releases, charts, test pods and local charts, run `make clean`

`helm test` will deploy a busybox container alongside the release which performs a simple HTTP request against the service health endpoint. If it doesn't return `HTTP 200` the test will fail. **NOTE:** it does NOT run with `--cleanup` so the test pod will be available for inspection.

### Troubleshooting

#### Docker image not found

For the purpose of testing this chart, we use a custom image built from the `/test-image` folder, especially as it exposes an `/health` endpoint and listens to the the port `3000`.

In the case this image is not found on the registry when you run the `make` command, you can build it locally and push it yourself to the sandbox registry.

You can use the `make push-test-image-sbx` command to create and push the image (make sure you are logged in with the right credentials/subscription)

You might have to to the same for the CI which uses the `hmctspublic.azurecr.io` registry with the `make push-test-image-non-prod` command.

#### Adding new resource fails in Azure Devops

You added a new job to the pipeline and it complains about a resource not being authorised: well this is too bad! Though Microsoft provides a workaround for you:

https://docs.microsoft.com/en-gb/azure/devops/pipelines/process/resources?view=vsts

## Azure DevOps Builds

Builds are run against the 'preview' AKS cluster.

- `azure-pipelines.yaml`: triggered when pull requests are created. This build will run `helm lint`, deploy the chart using `ci-values.yaml` and run `helm test`.
- `release.yaml`: triggered when the repository is tagged (e.g. when a release is created). Also performs linting and testing, and will publish the chart to ACR on success.
