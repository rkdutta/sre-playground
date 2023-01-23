#!/bin/bash

# install simple app

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm upgrade --install \
 hipster-shop open-telemetry/opentelemetry-demo \
 --values apps/hipster-shop-app/values.yaml