#!/bin/bash

# install prometheus operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install \
 prometheus prometheus-community/kube-prometheus-stack \
 --namespace prometheus \
 --create-namespace \
 --values prometheus/values.yaml

echo "`date` >>>>> wait for prometheus to be ready"
kubectl wait --namespace prometheus \
  --for=condition=ready pod \
  --selector=release=prometheus \
  --timeout=90s
kubectl wait --namespace prometheus \
  --for=condition=ready pod \
  --selector="app.kubernetes.io/instance=prometheus" \
  --timeout=90s
kubectl wait --namespace prometheus \
  --for=condition=ready pod \
  --selector="app.kubernetes.io/name=alertmanager" \
  --timeout=90s