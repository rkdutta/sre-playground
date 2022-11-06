#!/bin/bash

# install istio
ISTIO_VERSION="1.15.2"
curl -L https://istio.io/downloadIstio | sh -
istio-${ISTIO_VERSION}/bin/istioctl x precheck
istio-${ISTIO_VERSION}/bin/istioctl install --set profile=demo -y

# label system namespaces for istio
kubectl label ns default istio-injection=enabled

# install prometheus addon (required for kiali)
kubectl apply -f istio-${ISTIO_VERSION}/samples/addons/prometheus.yaml
until kubectl -n istio-system describe deployments.apps prometheus | grep "0 unavailable" > /dev/null; do
  echo "Waiting for prometheus to start.."
  sleep 2
done

# install kiali addon
kubectl apply -f istio-${ISTIO_VERSION}/samples/addons/kiali.yaml
until kubectl -n istio-system describe deployments.apps kiali | grep "0 unavailable" > /dev/null; do
  echo "Waiting for kiali to start.."
  sleep 2
done