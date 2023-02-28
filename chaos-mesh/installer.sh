#!/bin/bash
set -eo pipefail

app=${1:-"chaos-mesh"}
namespace=${2:-"chaos-mesh"}
clusterName=${3:-"sre-demo-site"}

#installing
helm repo add $app https://charts.chaos-mesh.org
helm upgrade --install $app chaos-mesh/chaos-mesh \
  --namespace=$namespace \
  --create-namespace \
  --version "2.5.1" \
  --values values.yaml \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock   # Default to /var/run/docker.sock

# create permissions for the dashboard user
kubectl apply -f permissions.yaml

# generate token for the dashboard user
echo && echo
echo ">>>> CHAOS MESH DASHBOARD URL: http://chaostest.sre-playground.com/dashboard"
echo ">>>> CHAOS MESH DASHBOARD TOKEN:"
kubectl -n chaos-mesh create token chaos-dashboard