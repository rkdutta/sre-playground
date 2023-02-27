#!/bin/bash

namespace="default"
app="hipster-shop"
selector="app.kubernetes.io/name=hipster-shop"

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade --install \
 $app open-telemetry/opentelemetry-demo \
 --namespace $namespace \
 --create-namespace \
 --values apps/hipster-shop-app/values.yaml

echo "`date` >>>>> wait for $app to be ready"
kubectl wait --namespace $namespace \
                --for=condition=ready pod \
                --selector=$selector \
                --timeout=90s
