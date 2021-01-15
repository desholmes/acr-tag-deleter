#!/bin/bash

set -e

echoError() { echo "Error: $@" >&2; }
echoInfo() { echo "Info: $@"; }

echoInfo "ACR RC Untagger (v$APP_VERSION)"

# Check required environment variables are set
for envVar in AZURE_TENANT \
         AZURE_SUBSCRIPTION \
         VERSION \
         REPO \
         REGISTRY_NAME \
         REGISTRY_USERNAME \
         REGISTRY_PASSWORD \
         DRY_RUN; do
  if [[ -z "${!envVar}" ]];
  then
    echoError "Required environment variable '$envVar' isn't set, script exiting."
    exit 1
  fi
done

## Dry run message
if [[ -z ${DRY_RUN} || ${DRY_RUN} != "1" ]];
then
  echoInfo "DRY_RUN is disabled, rc tags will be untagged"
else
  echoInfo "DRY_RUN is enabled, rc tags won't be untagged"
fi

echoInfo "Attempting to log into Azure"
az login --service-principal \
  -u "$REGISTRY_USERNAME" \
  -p "$REGISTRY_PASSWORD" \
  --tenant "$AZURE_TENANT" -o none

if [ $? -eq 0 ];
then
  echoInfo "Login successful"
else
  echoError "Login failed (exit code: $?), check the credentials are correct"
  exit 1
fi

function remove_rc_tags {
  ## Fetch RC images
  echoInfo "Attempting to fetch rc tags for repo: '$1', version: '$VERSION'"

  # Note: Incorrect REGISTRY_NAME or REPO will display 'az acr' message and exit 1
  allTags=$(az acr repository show-tags --subscription "$AZURE_SUBSCRIPTION" --name "$REGISTRY_NAME" --repository "$1")

  rcTags=$(echo "$allTags" | jq -c '[.[] | select(contains ("'$VERSION'rc"))]')
  rcCount=$(echo "$rcTags" | jq -c '. | length')

  # Do we have rc tags?
  if [[ -z ${rcCount} || ${rcCount} == "0" ]];
  then
    echoInfo "No rc tags found, exiting"
    return
  fi

  echoInfo "Fetching rc tags successful. Found: '$rcCount'"

  # Loop through RC tags and create a report, or untag them
  for tag in $(echo "${rcTags}" | jq -r '.[]');
  do
    if [[ -z ${DRY_RUN} || ${DRY_RUN} != "1" ]];
    then
      az acr repository untag --subscription "$AZURE_SUBSCRIPTION" --name "$REGISTRY_NAME" --image "$1:$tag"
      echoInfo "Untagged: '$1:$tag'"
    else
      echoInfo "DRY RUN - '$1:$tag' would have been untagged"
    fi
  done
}

while IFS=',' read -ra ADDR; do
  for i in "${ADDR[@]}"; do
    remove_rc_tags "$i"

    echoInfo "Removing untagged manifests from the repository '$i'"

    UNTAGGED_MANIFESTS=$(az acr repository show-manifests --subscription "$AZURE_SUBSCRIPTION" --name "$REGISTRY_NAME" --repository "$i"  --query "[?tags[0]==null].digest" -o tsv)

    if [[ -z ${DRY_RUN} || ${DRY_RUN} != "1" ]];
    then
      echoInfo "DRY_RUN is disabled, manifests with no tags will be deleted"
      echo "$UNTAGGED_MANIFESTS" | xargs -I% az acr repository delete --subscription "$AZURE_SUBSCRIPTION" --name "$REGISTRY_NAME" --image $i@% --yes
    else
      echoInfo "DRY_RUN is enabled, manifests with no tags won't be deleted"
      echo "$UNTAGGED_MANIFESTS" | xargs -I%  echo "Info: Manifest % would have been deleted"
    fi

  done
done <<< "$REPO"

echoInfo "ACR RC Untagger complete"
