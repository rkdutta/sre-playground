#!/bin/bash

sh ./install-cert-manager.sh
sh ./install-elk.sh

rm -rfd config
kubectl -n elasticsearch exec elasticsearch-es-default-0 -- tar cf - config/http-certs | tar xf -

kubectl create namespace observability
kubectl label ns observability istio-injection=disabled
PASSWORD=$(kubectl -n elasticsearch get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
kubectl -n observability delete secret jaeger-secret
kubectl -n observability create secret generic jaeger-secret \
  --from-literal=ES_PASSWORD=$PASSWORD \
  --from-literal=ES_USERNAME=elastic


kubectl -n observability delete secret elasticsearch-client-tls-certificates
kubectl -n elasticsearch exec elasticsearch-es-default-0 -- tar cf - config/http-certs | tar xf -
kubectl -n observability create secret generic elasticsearch-client-tls-certificates \
  --from-file=ca.crt=config/http-certs/ca.crt  \
  --from-file=tls.crt=config/http-certs/tls.crt \
  --from-file=tls.key=config/http-certs/tls.key 

kubectl -n observability create cm jaeger-tls \
  --from-file=ca.crt=config/http-certs/ca.crt  \
  --from-file=tls.crt=config/http-certs/tls.crt \
  --from-file=tls.key=config/http-certs/tls.key

# deleteing certificates
rm -rfd config

#installing
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm -n observability upgrade --install jaeger jaegertracing/jaeger \
  --values jaeger/jaeger-values.yaml \
  --set storage.elasticsearch.password=$PASSWORD