#!/bin/bash

helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluent-bit fluent/fluent-bit \
  --namespace=fluent-bit \
  --create-namespace \
  --values fluent-bit/values.yaml

echo "`date` >>>>> wait for fluent-bit to be ready"
kubectl wait --namespace fluent-bit \
                --for=condition=ready pod \
                --selector="app.kubernetes.io/instance=fluent-bit" \
                --timeout=90s