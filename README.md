# chart-nodejs

[![Build Status](https://dev.azure.com/hmcts/CNP/_apis/build/status/Helm%20Charts/chart-nodejs)](https://dev.azure.com/hmcts/CNP/_build/latest?definitionId=66)

Nodejs Applications Helm chart.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

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
      resourceGroup: cmc
      secrets:
        - smoke-test-citizen-username
        - smoke-test-ushmmer-password
    s2s:
      resourceGroup: rpe-service-auth-provider
      secrets:
        - microservicekey-cmcLegalFrontend
  applicationInsightsInstrumentKey: some-key
```

## Configuration

The following table lists the configurable parameters of the nodejs chart and their default values.
You most likely may override `image`, `applicationPort` and `environment` for your project.

| Parameter | Description | Default | 
| --------- | ----------- | ------- |
| `releaseNameOverride` | Will override the resource name - advised to use with pipeline variable SERVICE_NAME: `releaseNameOverride: ${SERVICE_NAME}-my-custom-name` | `Release.Name-Chart.Name` |
| `applicationPort` | The port your app runs on in its container| `3000` |
| `replicas` | Number of pod replicas | `1` |
| `useInterpodAntiAffinity` | Always schedule replicas on different nodes | `false` | 
| `image` | *REQUIRED*: Full image url ('${IMAGE}' in the values.template.yml ) | |
| `imagePullPolicy` | Kubernetes container image pull policy | `IfNotPresent` |
| `environment` | A map containing all environment values you wish to set. Values can be templated | `nil` |
| `configmap` | A config map, can be used for environment specific config | `nil` |
| `memoryRequests`| Requests for memory | `64Mi`|
| `cpuRequests` | Requests for cpu | `25m` |
| `memoryLimits` | Memory limits | `256Mi` |
| `cpuLimits` | CPU limits | `500m` |
| `ingressHost` | Host for ingress controller to map the container to| `nil` |
| `registerAdditionalDns.enabled` | If you want to use this chart as a secondary dependency - e.g. providing a frontend to a backend, and the backend is using primary ingressHost DNS mapping. Note: you will also need to define: `ingressIP: ${INGRESS_IP}` and `consulIP: ${CONSUL_LB_IP}` - this will be populated by pipeline | `false` |
| `registerAdditionalDns.primaryIngressHost`| The hostname for primary chart | `nil` |
| `registerAdditionalDns.prefix` | DNS prefix for this chart - will resolve as: `prefix-{registerAdditionalDns.primaryIngressHost}` | `nil` |  
| `readinessPath` | Path of HTTP readiness probe| `/health` |
| `readinessDelay` | Readiness probe inital delay (seconds) | `5` |
| `readinessTimeout` | Readiness probe timeout (seconds) | `3`|
| `readinessPeriod` | Readiness probe period (seconds) | `15`|
| `livenessPath` | Path of HTTP liveness probe | `/health/liveness`|
| `livenessDelay` | Liveness probe inital delay (seconds) | `5` |
| `livenessTimeout` | Liveness probe timeout (seconds) | `3` |
| `livenessPeriod` | Liveness probe period (seconds) | `15` |
| `livenessFailureThreshold`| Liveness failure threshold | `3` |
| `keyVaults`| This section is about adding the keyvault secrets to the file system see [Adding Azure Key Vault Secrets]()| none |
| `secrets`                  | Mappings of environment variables to service objects or pre-configured kubernetes secrets |  nil |
| `applicationInsightsInstrumentKey` | Instrumentation Key for App Insights , It is mapped to `APPINSIGHTS_INSTRUMENTATIONKEY` as environment variable | `00000000-0000-0000-0000-000000000000` |
| `pdb.enabled` | To enable PodDisruptionBudget on the pods for handling disruptions | `true` |
| `pdb.maxUnavailable` |  To configure the number of pods from the set that can be unavailable after the eviction. It can be either an absolute number or a percentage. pdb.minAvailable takes precedence over this if not nil | `50%` means evictions are allowed as long as no more than 50% of the desired replicas are unhealthy. It will allow disruption if you have only 1 replica.|
| `pdb.minAvailable` |  To configure the number of pods from that set that must still be available after the eviction, even in the absence of the evicted pod. minAvailable can be either an absolute number or a percentage. This takes precedence over pdb.maxUnavailable if not nil. | `nil`|
| `aadIdentityName` | Identity to assign to the pod, can be used for accessing azure resources such as key vault | `nil` |
| `prometheus.enabled` | Whether to add an annotation to the deployment to say scrape prometheus metrics | `false` |
| `prometheus.path` | Path for prometheus metrics | `/metrics` |

## Adding Azure Key Vault Secrets
Key vault secrets are mounted to the container filesystem using what's called a [flexvolume](https://github.com/Azure/kubernetes-keyvault-flexvol)
*encrypted* environment variables. This adds a very easy convenient way of accessing the key-vault.
To do this we need to add the **keyVaults** member to the configuration as below.
```yaml
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      resourceGroup: <VAULT_RESOURCE_GROUP>
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
    <VAULT_NAME_2>:
      resourceGroup: <VAULT_RESOURCE_GROUP_2>
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
```
**Where**:
- *<VAULT_NAME>*: This is the name of the vault to access without the environment tag i.e. `s2s` or `bulkscan`.
- *<VAULT_RESOURCE_GROUP>*: This is the resource group for the vault this also does not need the environment tag ie. for s2s vault it is `rpe-service-auth-provider`.
- *<SECRET_NAME>* This is the name of the secret as it is in the vault. Note this is case and punctuation sensitive. i.e. in s2s there is the `microservicekey-cmcLegalFrontend` secret.
- *excludeEnvironmentSuffix*: This is used for the global key vaults where there is not environment suffix ( e.g `-aat` ) required. It defaults to false if it is not there and should only be added if you are using a global key-vault.

If you wish to use pod identity for accessing the key vaults instead of a service principal you need to set a flag `aadIdentityName: <identity-name>`

**Note**: To enable `keyVaults` to be mounted as flexvolumes :
- When not using Jenkins, explicitly set global.enableKeyVaults to `true` .
- When not using pod identity, your service principal credentials need to be added to your namespace as a Kubernetes secret named `kvcreds` and accessible by the KeyVault FlexVolume driver. 

## Kubernetes Secrets
To add kubernetes secrets such as passwords and service keys to the Nodejs chart you can use the the secrets section.
The secrets section maps the secret to an environment variable in the container.
e.g :
```yaml
secrets: 
  CONNECTION_STRING:
      secretRef: some-secret-reference
      key: connectionString
      disabled: false
```
**Where:**
- **CONNECTION_STRING** is the environment variable to set to the value of the secret ( this has to be capitals and can contain numbers or "_" ).
- **secretRef** is the service instance ( as in the case of PaaS wrappers ) or reference to the secret volume. It supports templating in values.yaml . Example : secretRef: some-secret-reference-{{ .Release.Name }}
- **key** is the named secret in the secret reference.
- **disabled** is optional and used to disable setting this environment value. This can be used to override the behaviour of default chart secrets. 

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
