#!/bin/bash

helm repo add loki https://grafana.github.io/helm-charts
helm upgrade --install loki loki/loki-stack \
  --namespace=loki-stack \
  --create-namespace \
  --atomic \
  --values loki/loki-stack-values.yaml \
  --wait

kubectl get secret --namespace loki-stack loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

