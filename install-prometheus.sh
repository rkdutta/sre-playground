#!/bin/bash

# install prometheus operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install \
 prometheus prometheus-community/kube-prometheus-stack \
 --dependency-update \
 --atomic \
 --namespace prometheus \
 --create-namespace \
 --values prometheus/values.yaml

echo "`date` >>>>> prometheus started..."
