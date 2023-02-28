#!/bin/bash
set -eo pipefail

app=${1:-"cilium"}
namespace=${2:-"kube-system"}
clusterName=${3:-"sre-demo-site"}
selector=${4:-"nothing=specified"}

#installing cilium
helm repo add $app https://helm.cilium.io/
helm upgrade \
    --install $app $app/cilium \
    --namespace $namespace \
    --values values.yaml \
    --set k8sServiceHost=$clusterName-control-plane \
    --version 1.13.0

