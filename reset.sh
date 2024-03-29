#!/bin/bash
set -eo pipefail

#retrieve all namespaces
NAMESPACES=$(kubectl get namespace | awk '{print $1}' | tail -n +2)
# transpose the column into an array
NAMESPACES=( $( echo $NAMESPACES ) )

for ns in "${NAMESPACES[@]}"
do
      #except CNI which is installed in cilium
      if [[ "$ns" == "kube-system" ]]; then
        continue
      fi

    if helm ls -n $ns --no-headers | grep ""; then
        echo "Uninstalling helm charts from $ns namespace"
        helm ls -n $ns --short | xargs -L1 helm delete -n $ns
    fi
done

istioctl uninstall --purge
kubectl -n istio-system delete deployments.apps kiali  --ignore-not-found
kubectl -n istio-system delete deployments.apps prometheus  --ignore-not-found
kubectl delete ing -A --all