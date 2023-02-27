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
  --values values.yaml 


# ---
# #!/bin/bash

# set 
# namespace="default"
# app="hipster-shop"
# selector="app.kubernetes.io/name=hipster-shop"

# helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
# helm upgrade --install \
#  $app open-telemetry/opentelemetry-demo \
#  --namespace $namespace \
#  --create-namespace \
#  --values apps/hipster-shop-app/values.yaml

# echo "`date` >>>>> wait for $app to be ready"
# kubectl wait --namespace $namespace \
#                 --for=condition=ready pod \
#                 --selector=$selector \
#                 --timeout=90s
