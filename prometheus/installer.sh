#!/bin/bash
set -eo pipefail

app=${1:-"prometheus"}
namespace=${2:-"prometheus"}
clusterName=${3:-"sre-demo-site"}

#installing
helm repo add $app https://prometheus-community.github.io/helm-charts
helm upgrade --install $app prometheus-community/kube-prometheus-stack \
  --namespace=$namespace \
  --create-namespace \
  --values values.yaml \
  --version "45.3.0"
