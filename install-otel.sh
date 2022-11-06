#!/bin/bash

PASSWORD=$(kubectl -n elasticsearch get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')

# install opentelemetry
helm upgrade --install \
 opentelemetry opentelemetry/ \
 --namespace opentelemetry \
 --create-namespace \
 --dependency-update \
 --atomic \
 --set ES_PASSWORD=$PASSWORD \
 --wait

until kubectl -n opentelemetry-operator-system describe deployments.apps opentelemetry-operator-controller-manager | grep "0 unavailable" > /dev/null; do
  echo "Waiting for opentelemetry-operator to start.."
  sleep 2
done
echo "`date` >>>>> opentelemetry-operators started..."