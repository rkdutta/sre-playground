#!/bin/bash
set -eo pipefail

app=${1:-"fluent-bit"}
namespace=${2:-"fluent-bit"}
clusterName=${3:-"sre-demo-site"}

helm repo add $app https://fluent.github.io/helm-charts
helm upgrade --install $app fluent/fluent-bit \
  --namespace=$namespace \
  --create-namespace \
  --values values.yaml