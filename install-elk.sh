#!/bin/bash

# install elastic search
if ! kubectl -n elasticsearch describe statefulsets.apps elasticsearch-es-default | grep "0 Waiting" | grep "0 Failed" > /dev/null; then
helm upgrade --install \
 elasticsearch elasticsearch/ \
 --dependency-update \
 --atomic \
 --namespace elasticsearch \
 --create-namespace \
 --set ES_VERSION="7.17.7" \
 --wait 
fi

until kubectl -n elasticsearch describe statefulsets.apps elasticsearch-es-default | grep "0 Waiting" | grep "0 Failed" > /dev/null; do
  echo "Waiting for elasticsearch to start.."
  sleep 2
done

until kubectl -n elasticsearch get pods elasticsearch-es-default-0 -ojsonpath='{.status.containerStatuses[*].ready}' | grep -i "true"; do
echo "Waiting for elasticsearch to start.."
  sleep 2
done
echo "`date` >>>>> elastic search started..."