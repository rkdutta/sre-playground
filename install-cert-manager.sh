#!/bin/bash

# install cert-manager
if ! kubectl -n cert-manager describe deployments.apps cert-manager | grep "0 unavailable"; then
  
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.10.0 \
  --set installCRDs=true \
  --atomic

fi

until kubectl -n cert-manager describe deployments.apps cert-manager | grep "0 unavailable"; do
echo "`date` >>>>> waiting for cert-manager to start..."
sleep 2
done

echo "`date` >>>>> cert-manager started..."
