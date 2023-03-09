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



# ///////////////////////////////////////////////////////////////////////////////////////
#        VARIABLES
# ///////////////////////////////////////////////////////////////////////////////////////

ENABLE_KUBE_PROXY=${1:-true} # when false cilium will be installed and kube-proxy will be disabled
USE_LOCAL_IMAGES=${2:-false} # When true docker compose will run and create local images
RELEASE_VERSION="1.3.0" # Open Telemetry Community Demo Version. Check: https://github.com/open-telemetry/opentelemetry-demo
CLUSTER_NAME=${3:-"sre-demo-site"} # kind cluster name
DEMO_DIR="opentelemetry-demo" 
CONTAINER_REGISTRY="ghcr.io/open-telemetry/demo" # Used for temporary fix for arm64 cpu architecture 
CPU_ARCH="$(uname -m)"

DEMO_SERVICES=(
                "accountingservice"
                "adservice" 
                "cartservice"
                "checkoutservice"
                "currencyservice"
                "emailservice"
                "featureflagservice"
                "frauddetectionservice"
                "frontend"
                "frontendproxy"
                "kafka"
                "loadgenerator"
                "paymentservice"
                "productcatalogservice"
                "quoteservice"
                "recommendationservice"
                "shippingservice"
              )

# ///////////////////////////////////////////////////////////////////////////////////////

# Download the opentelemtry-demo repository and build images
if $USE_LOCAL_IMAGES ; then
  if [ -d $DEMO_DIR ]; then
    git --work-tree=$DEMO_DIR --git-dir=$DEMO_DIR/.git checkout $RELEASE_VERSION
    git pull
  else  
    git clone https://github.com/open-telemetry/opentelemetry-demo.git
    git fetch --all --tags
    git checkout $RELEASE_VERSION
    git pull
  fi
  # build
  ( cd $DEMO_DIR && docker compose build )
fi


# install kind cluster
if $ENABLE_KUBE_PROXY ; then
  KIND_CONFIG_FILE="kind/kind-config-enable-kube-proxy-$CPU_ARCH.yaml"
else
  KIND_CONFIG_FILE="kind/kind-config-disable-kube-proxy-$CPU_ARCH.yaml"
fi
echo "`date` >>>>> KIND_CONFIG_FILE=$KIND_CONFIG_FILE"
kind create cluster --config $KIND_CONFIG_FILE --name $CLUSTER_NAME || true


# Setting kubectl client context to the current cluster
kubectl config use-context kind-$CLUSTER_NAME

if kubectl get csr --no-headers | grep Pending | grep 'kubernetes.io/kubelet-serving' | grep system:node: ; then
  echo "here I am 2" 
  echo found pendingCSRs
  kubectl certificate approve $(kubectl get csr --no-headers | grep Pending | grep 'kubernetes.io/kubelet-serving' | grep system:node: | awk -F' ' '{print $1}')
fi

# verifying cluster installation 
app="control-plane"
selector="tier=control-plane"
namespace="kube-system"
waitForReadiness $app $namespace $selector

# transporting the locally build docker images to kind nodes
for i in "${DEMO_SERVICES[@]}"
do
   if $USE_LOCAL_IMAGES ; then
    echo ">> $CONTAINER_REGISTRY:$RELEASE_VERSION-$i"
    kind load docker-image  $CONTAINER_REGISTRY:$RELEASE_VERSION-$i --name $CLUSTER_NAME
   fi
done

# install cluster
helm dependency update sreplayground-cluster
helm upgrade --install sreplayground-cluster sreplayground-cluster \
--dependency-update   \
--namespace kube-system


if ! $ENABLE_KUBE_PROXY ; then
  # Install CNI: Cilium
  app="cilium"
  selector="k8s-app=cilium"
  namespace="kube-system"
  waitForReadiness $app $namespace $selector
  
else
  # verify default CNI installation
  app="cni-kindnet"
  selector="app=kindnet"
  namespace="kube-system"
  waitForReadiness $app $namespace $selector
fi

# calculate the CIDR range for metallb front-end address pool 
KIND_NET_CIDR=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.200@")
METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.250@")
METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"
echo $METALLB_IP_RANGE

# install platform components
helm dependency update sreplayground-platform
helm upgrade --install  sreplayground-platform sreplayground-platform \
--namespace platform \
--create-namespace \
--dependency-update \
--set metallb.addresspool=$METALLB_IP_RANGE

# install app
helm dependency update sreplayground-app
helm upgrade --install  sreplayground-app sreplayground-app \
--dependency-update \
--namespace app \
--create-namespace


echo "SUCCESS.."

