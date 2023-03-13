#!/bin/bash


kubectl create ns istio-system
# install istio
ISTIO_VERSION="1.17.1"
curl -L https://istio.io/downloadIstio | sh -
istio-${ISTIO_VERSION}/bin/istioctl x precheck
istio-${ISTIO_VERSION}/bin/istioctl install -y \
  --set values.gateways.istio-egressgateway.enabled=false \
  --set values.gateways.istio-ingressgateway.enabled=false


local_namespace="istio-system"
local_selector="app=istiod"
kubectl wait --namespace $local_namespace \
                --for=condition=ready pod \
                --selector=$local_selector \
                --timeout=90s

# install prometheus addon (required for kiali)
kubectl apply -f istio-${ISTIO_VERSION}/samples/addons/prometheus.yaml
local_namespace="istio-system"
local_selector="app=prometheus"
kubectl wait --namespace $local_namespace \
                --for=condition=ready pod \
                --selector=$local_selector \
                --timeout=90s

# install kiali addon
kubectl apply -f istio-${ISTIO_VERSION}/samples/addons/kiali.yaml
local_namespace="istio-system"
local_selector="app.kubernetes.io/name=kiali"
kubectl wait --namespace $local_namespace \
                --for=condition=ready pod \
                --selector=$local_selector \
                --timeout=90s


kubectl apply -f ingress-kiali.yaml