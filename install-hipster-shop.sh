#!/bin/bash

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade --install \
 hipster-shop open-telemetry/opentelemetry-demo \
 --namespace "hipster-shop" \
 --create-namespace \
 --values apps/hipster-shop-app/values.yaml
