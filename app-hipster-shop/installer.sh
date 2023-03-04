#!/bin/bash
set -eo pipefail

app=${1:-"app-hipster-shop"}
namespace=${2:-"default"}
clusterName=${3:-"sre-demo-site"}

indexFile="index.html"
#indexFile="index-local.html"

kubectl -n $namespace delete configmap dark-index-page --ignore-not-found
kubectl -n $namespace create configmap dark-index-page --from-file=index.html=$indexFile
kubectl -n $namespace apply -f deploy-index-page.yaml

#installing
helm repo add $app https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade --install $app $app/opentelemetry-demo \
  --namespace=$namespace \
  --create-namespace \
  --values values.yaml \
  --version 0.19.0
