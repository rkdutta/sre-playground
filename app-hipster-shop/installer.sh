#!/bin/bash
set -eo pipefail

app=${1:-"app-hipster-shop"}
namespace=${2:-"default"}
clusterName=${3:-"sre-demo-site"}

#installing
helm repo add $app https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade --install $app open-telemetry/opentelemetry-demo \
  --namespace=$namespace \
  --create-namespace \
  --values values.yaml \
  --version 0.19.0
