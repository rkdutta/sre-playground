#!/bin/bash
set -eo pipefail

app=${1:-"loki"}
namespace=${2:-"loki"}
clusterName=${3:-"sre-demo-site"}

#installing loki
helm repo add $app https://grafana.github.io/helm-charts
helm upgrade --install $app $app/loki-stack \
  --namespace=$namespace \
  --create-namespace \
  --values values.yaml \
  --version "2.9.9"

