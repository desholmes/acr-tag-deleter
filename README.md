# Azure Container Registry Release Candidate Docker Image Deleter

A [dockerised](https://hub.docker.com/r/desholmes/acr-rc-deleter) bash script using the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) to delete [Release Candidate (RC)](https://semver.org/spec/v2.0.0-rc.1.html) docker image tags from [Azure Container Registry (ACR)](https://docs.microsoft.com/en-us/azure/container-registry/).

Before using the Docker container in your pipeline you'll need to create a [service principle with access to ACR](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal).

## Usage

See the [Environment Variables](#environment-variables) table below.

The following example would check the repo `dholmes/acr-tag-deleter` for [RC](https://semver.org/spec/v2.0.0-rc.1.html) tags of `0.1.0`, but not delete them:

```bash
docker run -it \
  -e AZURE_TENANT=000-000-000-000 \
  -e AZURE_SUBSCRIPTION=000-000-000-000 \
  -e REGISTRY_NAME=dholmes \
  -e REGISTRY_USERNAME=username \
  -e REGISTRY_PASSWORD=password \
  -e REPO=acr-tag-deleter \
  -e TAG=0.1.0 \
  -e DRY_RUN=1 \
desholmes/acr-rc-deleter:1.0.0
```

### Environment Variables

| Environment Variable | Description |
|---|---|
|`AZURE_TENANT`|[Locate your Azure Account Tenant ID](https://microsoft.github.io/AzureTipsAndTricks/blog/tip153.html)|
|`AZURE_SUBSCRIPTION`|[Locate your Azure Subscription ID](https://docs.bitnami.com/azure/faq/administration/find-subscription-id/)|
|`REGISTRY_NAME`|[Locate your ACR name](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal)|
|`REGISTRY_USERNAME`|The [service principle](https://azure.microsoft.com/en-gb/resources/cloud-computing-dictionary/what-is-a-cloud-provider/) username|
|`REGISTRY_PASSWORD`|The [service principle](https://azure.microsoft.com/en-gb/resources/cloud-computing-dictionary/what-is-a-cloud-provider/) password|
|`REPO`|The docker repo you want to check/delete the tags from|
|`TAG`|The stable version of your tag, ie `0.1.0` for release candidates `0.1.0-rc.15`, `0.1.0-rc.16`|
|`DRY_RUN`|Boolean `1` to output the number of tags, `0` to delete the tags|

## Development

The docker image tag, registry and repo are tracked in the [Makefile](./Makefile).

### Make Commands

Make commands are included in this repo to automate the repetitive tasks. Copy [.env-dist](./.env-dist) to `.env` and populate the details before using the commands below.

| Command | Description |
|---|---|
|`make build`|Builds the Docker image using the version in [./version.properties](./version.properties) as the tag|
|`make build-push`|Runs `make build` and `make push`|
|`make clean-dangling-images`|Removes intermediate Docker images|
|`make delete-image`| Removes the Docker image based|
|`make push`|Pushes the Docker image into the registry|
|`make run`|Runs the built Docker image as a container bind mounts the `./app/` folder into the container for live reloading|
|`make run-clean`|Runs `make delete-image`, `make build` and `make run`|
