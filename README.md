# chart-nodejs

Nodejs Applications Helm chart.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

## Example configuration

```
applicationPort: 8080
environment:
  REFORM_TEAM: cnp
  REFORM_SERVICE_NAME: rhubarb-frontend
  REFORM_ENVIRONMENT: preview
  ROOT_APPENDER: CNP
configmap:
  VAR_A: VALUE_A
  VAR_B: VALUE_B
```

## Configuration

The following table lists the configurable parameters of the nodejs chart and their default values.
You most likely may override `image`, `applicationPort` and `environment` for your project.

| Parameter                  | Description                                               | Default                                                                        |
| -------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `applicationPort`          | The port your app runs on in its container                | `1337`                                                                         |
| `image`                    | Full image url                                            | `hmctssandbox.azurecr.io/hmcts/custard-frontend` (but overridden by pipeline)  |
| `environment`              | A map containing all environment values you wish to set   | `nil`                                                                          |
| `configmap`                | A config map, can be used for environment specific config | `nil`                                                                          |
| `memoryRequests`           | Requests for memory                                       | `64Mi`                                                                         |
| `cpuRequests`              | Requests for cpu                                          | `100m`                                                                         |
| `memoryLimits`             | Memory limits                                             | `256Mi`                                                                        |
| `cpuLimits`                | CPU limits                                                | `500m`                                                                         |
| `ingressHost`              | Host for ingress controller to map the container to       | `custard-helm.service.core-compute-saat.internal` (but overridden by pipeline) |
| `readinessPath`            | Path of HTTP readiness probe                              | `/health`                                                                      |
| `readinessDelay`           | Readiness probe inital delay (seconds)                    | `5`                                                                            |
| `readinessTimeout`         | Readiness probe timeout (seconds)                         | `3`                                                                            |
| `readinessPeriod`          | Readiness probe period (seconds)                          | `15`                                                                           |
| `livenessPath`             | Path of HTTP liveness probe                               | `/health`                                                                      |
| `livenessDelay`            | Liveness probe inital delay (seconds)                     | `5`                                                                            |
| `livenessTimeout`          | Liveness probe timeout (seconds)                          | `3`                                                                            |
| `livenessPeriod`           | Liveness probe period (seconds)                           | `15`                                                                           |
| `livenessFailureThreshold` | Liveness failure threshold                                | `3`                                                                            |

## Development and Testing

Default configuration (e.g. default image and ingress host) is setup for sandbox. This is suitable for local development and testing.

- Ensure you have logged in with `az cli` and are using `sandbox` subscription (use `az account show` to display the current one).
- For local development see the `Makefile` for available targets.
- To execute an end-to-end build, deploy and test run `make`.
- to clean up deployed releases, charts, test pods and local charts, run `make clean`

`helm test` will deploy a busybox container alongside the release which performs a simple HTTP request against the service health endpoint. If it doesn't return `HTTP 200` the test will fail. **NOTE:** it does NOT run with `--cleanup` so the test pod will be available for inspection.

### Troubleshooting

#### Docker image not found

For the purpose of testing this chart, we use the [Rhubarb](https://github.com/hmcts/cnp-rhubarb-frontend) frontend app image, especially as it exposes an `/health` endpoint.

In the case this image is not found on the registry when you run the `make` command, you can build it locally and push it yourself to the sandbox registry.

```bash
# ...In Rhubarb frontend repo root folder.
# Also make sure you are logged in with the sandbox subscription

$ docker build -t hmctssandbox.azurecr.io/hmcts/custard-frontend .

$ docker push hmctssandbox.azurecr.io/hmcts/custard-frontend
```

#### Adding new resource fails in Azure Devops

You added a new job to the pipeline and it complains about a resource not being authorised: well this is too bad, however Microsoft has a workaround for you:

https://docs.microsoft.com/en-gb/azure/devops/pipelines/process/resources?view=vsts

## Azure DevOps Builds

Builds are run against the 'nonprod' AKS cluster.

- `azure-pipelines.yaml`: triggered when pull requests are created. This build will run `helm lint`, deploy the chart using `ci-values.yaml` and run `helm test`.
- `release.yaml`: triggered when the repository is tagged (e.g. when a release is created). Also performs linting and testing, and will publish the chart to ACR on success.
