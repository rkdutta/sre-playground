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

installer(){
  local_app=$1
  local_namespace=$2
  local_clusterName=$3
  local_selector=$4
  (
    cd $local_app && \
    ./installer.sh $*
  )
  waitForReadiness $local_app $local_namespace $local_selector
}
# ///////////////////////////////////////////////////////////////////////////////////////



# ///////////////////////////////////////////////////////////////////////////////////////
#        VARIABLES
# ///////////////////////////////////////////////////////////////////////////////////////

ENABLE_KUBE_PROXY=${1:-true} # when false cilium will be installed
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

# verifying cluster installation 
app="control-plane"
selector="tier=control-plane"
namespace="kube-system"
waitForReadiness $app $namespace $selector


if ! $ENABLE_KUBE_PROXY ; then
  # Install CNI: Cilium
  app="cilium"
  selector="k8s-app=cilium"
  namespace="kube-system"
  installer $app $namespace $CLUSTER_NAME $selector
  else
  # verify deefault CNI installation
  app="cni-kindnet"
  selector="app=kindnet"
  namespace="kube-system"
  waitForReadiness $app $namespace $selector
fi

# verifying cluster installation 
app="kube-dns"
selector="k8s-app=kube-dns"
namespace="kube-system"
waitForReadiness $app $namespace $selector
kubectl get pods -A


# transporting the locally build docker images to kind nodes
for i in "${DEMO_SERVICES[@]}"
do
   if $USE_LOCAL_IMAGES ; then
    echo ">> $CONTAINER_REGISTRY:$RELEASE_VERSION-$i"
    kind load docker-image  $CONTAINER_REGISTRY:$RELEASE_VERSION-$i --name $CLUSTER_NAME
   fi
done


#install loki
app="loki"
selector="app=loki"
namespace="loki"
installer $app $namespace $CLUSTER_NAME $selector

#install fluent-bit
app="fluent-bit"
selector="app.kubernetes.io/instance=fluent-bit"
namespace="fluent-bit"
installer $app $namespace $CLUSTER_NAME $selector


#install prometheus
app="prometheus"
selector="release=prometheus"
namespace="prometheus"
installer $app $namespace $CLUSTER_NAME $selector
selector="app.kubernetes.io/instance=prometheus"
waitForReadiness $app $namespace $selector
selector="app.kubernetes.io/name=alertmanager"
waitForReadiness $app $namespace $selector
selector="app.kubernetes.io/managed-by=prometheus-operator"
waitForReadiness $app $namespace $selector


#install hipster application
app="app-hipster-shop"
selector="app.kubernetes.io/name=app-hipster-shop"
namespace="default"
installer $app $namespace $CLUSTER_NAME $selector


#install metallb
( cd metallb &&  ./installer.sh )

# # Install CNI: Enable Hubble ui
# EnableHubbleUISwitch=false
# sh install-cilium.sh $CLUSTER_NAME $EnableHubbleUISwitch


#install ingress controller
app="ingress"
selector="app.kubernetes.io/name=ingress-nginx"
namespace="ingress"
installer $app $namespace $CLUSTER_NAME $selector


#install chaos-mesh and execute
app="chaos-mesh"
selector="app.kubernetes.io/instance=chaos-mesh"
namespace="chaos-mesh"
installer $app $namespace $CLUSTER_NAME $selector
selector="app.kubernetes.io/component=chaos-daemon"
waitForReadiness $app $namespace $selector


# Apply the ingress rules
kubectl apply -f ingress/ingress-rules.yaml

echo "SUCCESS.."