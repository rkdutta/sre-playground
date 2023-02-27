#!/bin/bash
set -eo pipefail

app=${1:-"loki"}
namespace=${2:-"loki"}
clusterName=${3:-"sre-demo-site"}

#installing loki
helm repo add $app https://grafana.github.io/helm-charts
helm upgrade --install $app loki/loki-stack \
  --namespace=$namespace \
  --create-namespace \
  --values values.yaml 

