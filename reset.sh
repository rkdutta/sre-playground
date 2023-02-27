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

kubectl delete -f ingress-nginx/ingress-rules.yaml
kubectl delete -f ingress-nginx/nginx-ingress-def.yaml