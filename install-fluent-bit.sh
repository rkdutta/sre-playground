#!/bin/bash

helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluent-bit fluent/fluent-bit \
  --namespace=fluent-bit \
  --create-namespace \
  --values fluent-bit/values.yaml

