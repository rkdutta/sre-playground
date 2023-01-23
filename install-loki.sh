#!/bin/bash

kubectl create ns loki-stack
helm repo add loki https://grafana.github.io/helm-charts
helm upgrade --install loki loki/loki-stack \
  --namespace=loki-stack \
  --create-namespace \
  --atomic \
  --values loki/values.yaml \
  --wait

