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


KUBEPROXY_OPTS=${1:-"with-kubeproxy"}
CNI=${2:-"cilium"}
CLUSTER_NAME=${3:-"sre-playground"}


KIND_CONFIG_FILE=`mktemp`
OVERRIDE_CONFIG_FILE=`mktemp`
CPU_ARCH="$(uname -m)"
PLAYGROUND_CONFIG_FILE="kind/bootstrap-config.yaml"

# reading kind cluster common configuration
yq .common-config.$CPU_ARCH $PLAYGROUND_CONFIG_FILE > $KIND_CONFIG_FILE
yq .override-config.$KUBEPROXY_OPTS.$CNI.kind-patch $PLAYGROUND_CONFIG_FILE >> $KIND_CONFIG_FILE

# install kind cluster
echo "`date` >>>>> Creating kind cluster:$CLUSTER_NAME $KUBEPROXY_OPTS for $CPU_ARCH cpu architecture with CNI:$CNI"
kind create cluster --config $KIND_CONFIG_FILE --name $CLUSTER_NAME || true
# Setting kubectl client context to the current cluster
kubectl config use-context kind-$CLUSTER_NAME

# approve kubelet-serving CertificateSigningRequests
if kubectl get csr --no-headers | grep Pending | grep 'kubernetes.io/kubelet-serving' | grep system:node: ; then
  echo "`date` >>>>> Found pending certificate signing requests from kubelet"
  kubectl certificate approve $(kubectl get csr --no-headers | grep Pending | grep 'kubernetes.io/kubelet-serving' | grep system:node: | awk -F' ' '{print $1}')
fi

# verifying cluster installation 
waitForReadiness "control-plane" "kube-system" "tier=control-plane"

# calculate the CIDR range for metallb front-end address pool 
KIND_NET_CIDR=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.200@")
METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.250@")
METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"
echo "`date` >>>>> METALLB_IP_RANGE:$METALLB_IP_RANGE"


# install cluster
yq .override-config.$KUBEPROXY_OPTS.$CNI.cni-patch $PLAYGROUND_CONFIG_FILE > $OVERRIDE_CONFIG_FILE
echo "`date` >>>>> OVERRIDE_CONFIG_FILE:$OVERRIDE_CONFIG_FILE"
helm dependency update sreplayground-cluster
helm upgrade --install sreplayground-cluster sreplayground-cluster \
--dependency-update   \
--namespace kube-system \
--set metallb.addresspool=$METALLB_IP_RANGE --wait \
--set $CNI.enabled=true \
--set cilium.k8sServiceHost=$CLUSTER_NAME-control-plane \
--set cilium.ipMasqAgent.enabled=$(yq .ipMasqAgent.enabled $OVERRIDE_CONFIG_FILE) \
--set cilium.kubeProxyReplacement=$(yq .kubeProxyReplacement $OVERRIDE_CONFIG_FILE)

# TO BE DISCUSSED BEFORE ENABLING ISTIO
#install istio and kiali 
#(cd istio && ./istio.sh)

# install platform components
kubectl create namespace platform --dry-run=client -o yaml | kubectl apply -f -
helm dependency update sreplayground-platform
helm upgrade --install  sreplayground-platform sreplayground-platform \
--namespace platform \
--create-namespace \
--dependency-update \
--wait


# install app
kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install  sreplayground-app sreplayground-app \
--dependency-update \
--namespace app \
--create-namespace


# install testing
kubectl create namespace testing --dry-run=client -o yaml | kubectl apply -f -
helm dependency update sreplayground-testing
helm upgrade --install  sreplayground-testing sreplayground-testing \
--dependency-update \
--namespace testing \
--create-namespace


echo "SUCCESS.."

