#!/bin/bash
set -eo pipefail

# Pre-requisites for using Docker Desktop
# Set the Virtual disk limit: 100 GB
# For better performance set the memory: 20 GB

clear

# ///////////////////////////////////////////////////////////////////////////////////////
#        FUNCTIONS
# ///////////////////////////////////////////////////////////////////////////////////////

waitForReadiness(){
  local_app=$1
  local_namespace=$2
  local_selector=$3
  echo "`date` >>>>> wait for $local_app to be ready"
  kubectl wait --namespace $local_namespace \
                --for=condition=ready pod \
                --selector=$local_selector \
                --timeout=90s
}

# ///////////////////////////////////////////////////////////////////////////////////////


CLUSTER_NAME=${2:-"sre-demo-site"} 
KIND_CONFIG_FILE=`mktemp`
CPU_ARCH="$(uname -m)"
PLAYGROUND_CONFIG_FILE="kind/bootstrap-config.yaml"

KUBEPROXY_OPTS=${1:-"with-kubeproxy"}
# reading kind cluster configuration
yq .kind-configs.$KUBEPROXY_OPTS.$CPU_ARCH $PLAYGROUND_CONFIG_FILE > $KIND_CONFIG_FILE

# install kind cluster
echo "`date` >>>>> Creating kind cluster $KUBEPROXY_OPTS for $CPU_ARCH"
kind create cluster --config $KIND_CONFIG_FILE --name $CLUSTER_NAME || true

# Setting kubectl client context to the current cluster
kubectl config use-context kind-$CLUSTER_NAME

# approve kubelet-serving CertificateSigningRequests
if kubectl get csr --no-headers | grep Pending | grep 'kubernetes.io/kubelet-serving' | grep system:node: ; then
  echo found pendingCSRs
  kubectl certificate approve $(kubectl get csr --no-headers | grep Pending | grep 'kubernetes.io/kubelet-serving' | grep system:node: | awk -F' ' '{print $1}')
fi

# verifying cluster installation 
waitForReadiness "control-plane" "kube-system" "tier=control-plane"

# calculate the CIDR range for metallb front-end address pool 
KIND_NET_CIDR=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.200@")
METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.250@")
METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"
echo $METALLB_IP_RANGE


# install cluster
CNI=$(yq .kind-configs.$KUBEPROXY_OPTS.cni $PLAYGROUND_CONFIG_FILE)
helm dependency update sreplayground-cluster
helm upgrade --install sreplayground-cluster sreplayground-cluster \
--dependency-update   \
--namespace kube-system \
--set cni.$CNI.enabled=true \
--set metallb.addresspool=$METALLB_IP_RANGE --wait


# verifying cni installation
CNI_POD_SELECTOR=$(yq .kind-configs.$KUBEPROXY_OPTS.cni-pod-selector $PLAYGROUND_CONFIG_FILE) 
waitForReadiness "cni-$CNI" "kube-system" $CNI_POD_SELECTOR


#install istio and kiali
#(cd istio && ./istio.sh)

# install platform components
kubectl create namespace platform --dry-run=client -o yaml | kubectl apply -f -
#kubectl label ns platform istio-injection=enabled
helm dependency update sreplayground-platform
helm upgrade --install  sreplayground-platform sreplayground-platform \
--namespace platform \
--create-namespace \
--dependency-update \
--wait
 

# install app
kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
kubectl label ns app istio-injection=enabled
#helm dependency update sreplayground-app
helm upgrade --install  sreplayground-app sreplayground-app \
--dependency-update \
--namespace app \
--create-namespace


# install testing
kubectl create namespace testing --dry-run=client -o yaml | kubectl apply -f -
kubectl label ns testing istio-injection=enabled
helm dependency update sreplayground-testing
helm upgrade --install  sreplayground-testing sreplayground-testing \
--dependency-update \
--namespace testing \
--create-namespace


echo "SUCCESS.."

