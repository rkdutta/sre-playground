#!/bin/bash
set -eo pipefail

app=${1:-"sre-demo-ingress"}
namespace=${2:-"ingress"}
selector=${3:-"app.kubernetes.io/name=ingress-nginx"}


helm upgrade --install $app ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace $namespace --create-namespace \
  --values values.yaml \
  --version "4.5.2" 






