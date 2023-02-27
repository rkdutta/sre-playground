#!/bin/bash

helm repo add loki https://grafana.github.io/helm-charts
helm upgrade --install loki loki/loki-stack \
  --namespace=loki \
  --create-namespace \
  --values loki/values.yaml 

echo "`date` >>>>> wait for loki to be ready"
kubectl wait --namespace loki \
                --for=condition=ready pod \
                --selector=app=loki \
                --timeout=90s