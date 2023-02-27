#!/bin/bash
set -eo pipefail

app=${1:-"chaos-mesh"}
namespace=${2:-"chaos-mesh"}
clusterName=${3:-"sre-demo-site"}

#Executing chaos experiment workflow:
kubectl apply -f workflows/chaos-workflow.yaml