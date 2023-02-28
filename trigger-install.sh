#!/bin/bash
set -eo pipefail

# Pre-requisites for using Docker Desktop
# Set the Virtual disk limit: 100 GB
# For better performance set the memory: 20 GB

clear

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

# DECLARING SCRIPT VARIABLES
USE_LOCAL_IMAGES=false
FORCE_BUILD_IMAGES_LOCALLY=false
clusterName="sre-demo-site"
ENABLE_KUBE_PROXY=true

DEMO_DIR="opentelemetry-demo"
RELEASE_VERSION="1.3.0"
CONTAINER_REGISTRY="ghcr.io/open-telemetry/demo"

if $ENABLE_KUBE_PROXY ; then
  KIND_CONFIG_FILE="kind/kind-config-enable-kube-proxy.yaml"
else
  KIND_CONFIG_FILE="kind/kind-config-disable-kube-proxy.yaml"
fi

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

#download or sync the opentelemtry-demo repository
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
fi

# build images locally for arm64 CPU architecture
if $FORCE_BUILD_IMAGES_LOCALLY ; then
    cd $DEMO_DIR
    docker compose build
    cd ..
  fi

#kind delete clusters sre-demo-site
kind create cluster --config $KIND_CONFIG_FILE --name $clusterName || true

# Setting kubectl client context to the current cluster
kubectl config use-context kind-$clusterName

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
  installer $app $namespace $clusterName $selector
fi

# verifying cluster installation 
app="kube-dns"
selector="k8s-app=kube-dns"
namespace="kube-system"
waitForReadiness $app $namespace $selector


# transporting the locally build docker images to kind nodes
for i in "${DEMO_SERVICES[@]}"
do
   if $USE_LOCAL_IMAGES ; then
    echo ">> $CONTAINER_REGISTRY:$RELEASE_VERSION-$i"
    kind load docker-image  $CONTAINER_REGISTRY:$RELEASE_VERSION-$i --name $clusterName
   fi
done


#install loki
app="loki"
selector="app=loki"
namespace="loki"
installer $app $namespace $clusterName $selector

#install fluent-bit
app="fluent-bit"
selector="app.kubernetes.io/instance=fluent-bit"
namespace="fluent-bit"
installer $app $namespace $clusterName $selector


#install prometheus
app="prometheus"
selector="release=prometheus"
namespace="prometheus"
installer $app $namespace $clusterName $selector
selector="app.kubernetes.io/instance=prometheus"
waitForReadiness $app $namespace $selector
selector="app.kubernetes.io/name=alertmanager"
waitForReadiness $app $namespace $selector
selector="app.kubernetes.io/managed-by=prometheus-operator"
waitForReadiness $app $namespace $selector


#install hipster application
#sh install-hipster-shop.sh
app="app-hipster-shop"
selector="app.kubernetes.io/name=app-hipster-shop"
namespace="default"
installer $app $namespace $clusterName $selector


#install chaos-mesh and execute
#(cd chaosmesh && ./installer.sh)
app="chaos-mesh"
selector="app.kubernetes.io/instance=chaos-mesh"
namespace="chaos-mesh"
installer $app $namespace $clusterName $selector
selector="app.kubernetes.io/component=chaos-daemon"
waitForReadiness $app $namespace $selector

#To Dos:
# #install metallb
# sh metallb/install-metalb.sh

# # Install CNI: Enable Hubble ui
# EnableHubbleUISwitch=false
# sh install-cilium.sh $clusterName $EnableHubbleUISwitch


#install ingress controller
# sh install-ingress.sh
app="ingress-nginx"
selector="app.kubernetes.io/component=controller"
namespace="ingress-nginx"
installer $app $namespace $clusterName $selector


echo "SUCCESS.."