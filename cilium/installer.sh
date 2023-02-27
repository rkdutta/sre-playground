#!/bin/bash
set -eo pipefail

app=${1:-"cilium"}
namespace=${2:-"kube-system"}
clusterName=${3:-"sre-demo-site"}
selector=${4:-"nothing=specified"}

#installing cilium
helm repo add $app https://helm.cilium.io/
helm upgrade \
    --install $app cilium/cilium \
    --namespace $namespace \
    --values values.yaml \
    --set k8sServiceHost=$clusterName-control-plane


   #LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}') 
   # --set hubble.ui.enabled=$EnableHubbleSwitch \
   # --set hubble.ui.ingress.hosts[0]="hubble-ui.${LB_IP}.nip.io" \

# verify Masquerading
#kubectl -n kube-system exec ds/cilium -- cilium status | grep Masquerading

