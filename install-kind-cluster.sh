#!/bin/bash

# Pre-requisites for using Docker Desktop
# Set the Virtual disk limit: 100 GB
# For better performance set the memory: 20 GB

clear

USE_LOCAL_IMAGES=false
FORCE_BUILD_IMAGES_LOCALLY=false
ClusterName="sre-demo-site"
KIND_CONFIG_FILE="kind/kind-config-NoCNI.yaml"
DEMO_DIR="opentelemetry-demo"
RELEASE_VERSION="1.3.0"
CONTAINER_REGISTRY="ghcr.io/open-telemetry/demo"
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
if [ -d $DEMO_DIR ]; then
  git --work-tree=$DEMO_DIR --git-dir=$DEMO_DIR/.git pull origin main
else
  if $USE_LOCAL_IMAGES ; then
    git clone https://github.com/open-telemetry/opentelemetry-demo.git
  fi
fi

# build images locally for arm64 CPU architecture
if $FORCE_BUILD_IMAGES_LOCALLY ; then
    cd $DEMO_DIR
    docker compose build
    cd ..
  fi

# Setting kubectl client context to the current cluster
kubectl config use-context kind-$ClusterName

#kind delete clusters sre-demo-site
kind create cluster --config $KIND_CONFIG_FILE --name $ClusterName

# Setting kubectl client context to the current cluster
kubectl config use-context kind-$ClusterName


# checking kubernetes status
# until kubectl get sa default 2>&1 > /dev/null; do
#   echo "Waiting for Kubernetes to start..."
#   sleep 1
# done
# echo " `date` >>>>> kubernetes started..."
# Checking if apiserver, etcd, controller-manager, scheduler is running

echo "`date` >>>>> wait for controle-plane components to be ready"
kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector=tier=control-plane \
  --timeout=90s


# Install CNI: Cilium
EnableHubbleUISwitch=false
sh install-cilium.sh $ClusterName $EnableHubbleUISwitch

# verifying if coreDNS pods are up and running
# until kubectl -n kube-system describe deployments.apps coredns | grep "0 unavailable"; do
#   kubectl -n kube-system rollout restart deployment coredns
#   echo "Waiting for coredns pods to start.."
#   sleep 20
# done
# echo "`date` >>>>> coreDNS started..."
# echo "`date` >>>>> cluster created successfully..."

echo "`date` >>>>> wait for kube-dns to be ready"
kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector=k8s-app=kube-dns \
  --timeout=90s


# transporting the locally build docker images to kind nodes
for i in "${DEMO_SERVICES[@]}"
do
   if $USE_LOCAL_IMAGES ; then
    echo ">> $CONTAINER_REGISTRY:$RELEASE_VERSION-$i"
    kind load docker-image  $CONTAINER_REGISTRY:$RELEASE_VERSION-$i --name $ClusterName
   fi
done


#install loki
sh install-loki.sh

#install fluent-bit
sh install-fluent-bit.sh

#install prometheus
sh install-prometheus.sh

#install ingress controller
sh install-ingress.sh

#install hipster application
sh install-hipster-shop.sh

# #install metallb
# sh metallb/install-metalb.sh

# # Install CNI: Enable Hubble ui
# EnableHubbleUISwitch=false
# sh install-cilium.sh $ClusterName $EnableHubbleUISwitch


echo "SUCCESS.."