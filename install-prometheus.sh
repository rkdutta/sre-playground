#!/bin/bash

# install prometheus operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install \
 prometheus prometheus-community/kube-prometheus-stack \
 --dependency-update \
 --atomic \
 --namespace prometheus \
 --create-namespace \
 --values prometheus/prometheus-chart-values.yaml \
 --wait

echo "`date` >>>>> prometheus started..."
