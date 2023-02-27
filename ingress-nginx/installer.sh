#!/bin/bash
set -eo pipefail

app=${1:-"ingress-nginx"}
namespace=${2:-"ingress-nginx"}
selector=${3:-"app.kubernetes.io/component=controller"}

kubectl apply -f ./