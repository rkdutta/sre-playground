#!/bin/bash

kubectl apply -f ingress/nginx-ingress-def.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
kubectl apply -f ingress/ingress-rules.yaml