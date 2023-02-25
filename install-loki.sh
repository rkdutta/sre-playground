#!/bin/bash

helm repo add loki https://grafana.github.io/helm-charts
helm upgrade --install loki loki/loki-stack \
  --namespace=loki \
  --create-namespace \
  --values loki/values.yaml 
