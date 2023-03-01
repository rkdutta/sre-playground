#!/bin/bash
set -eo pipefail

app=${1:-"sre-demo-ingress"}
namespace=${2:-"ingress"}
selector=${3:-"app=$app-nginx-ingress"}

helm repo add $app https://helm.nginx.com/stable
helm upgrade --install $app $app/nginx-ingress \
  --namespace=$namespace \
  --create-namespace \
  --values values.yaml \
  --version 0.16.2

# install the ingress rules
kubectl apply -f ingress-rules.yaml