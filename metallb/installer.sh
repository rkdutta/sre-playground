#!/bin/bash
set -eo pipefail

app=${1:-"metallb"}
namespace=${2:-"metallb-system"}
selector=${3:-"app.kubernetes.io/name=metallb"}


KIND_NET_CIDR=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.200@")
METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.250@")
METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"
echo $METALLB_IP_RANGE



helm repo add $app https://metallb.github.io/metallb
helm upgrade --install $app $app/metallb \
  --namespace=$namespace \
  --create-namespace 
  # --values values.yaml \
  # --version 0.16.2

# ToDo: for eBPF
#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

kubectl wait --namespace $namespace \
                --for=condition=ready pod \
                --selector=$selector \
                --timeout=90s

kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: $namespace
spec:
  addresses:
    - $METALLB_IP_RANGE
EOF

kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: $namespace
spec:
  ipAddressPools:
    - first-pool
EOF

