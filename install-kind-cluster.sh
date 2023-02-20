#!/bin/bash

# Pre-requisites for using Docker Desktop
# Set the Virtual disk limit: 100 GB
# For better performance set the memory: 20 GB

USE_LOCAL_IMAGES=true
FORCE_BUILD_IMAGES_LOCALLY=true
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
until kubectl get sa default 2>&1 > /dev/null; do
  echo "Waiting for Kubernetes to start..."
  sleep 1
done
echo " `date` >>>>> kubernetes started..."

# Install CNI: Cilium
sh install-cilium.sh $ClusterName

# verifying if coreDNS pods are up and running
until kubectl -n kube-system describe deployments.apps coredns | grep "0 unavailable"; do
  kubectl -n kube-system rollout restart deployment coredns
  echo "Waiting for coredns pods to start.."
  sleep 20
done
echo "`date` >>>>> coreDNS started..."
echo "`date` >>>>> cluster created successfully..."

# verify Masquerading
kubectl -n kube-system exec ds/cilium -- cilium status | grep Masquerading


# transporting the locally build docker images to kind nodes
for i in "${DEMO_SERVICES[@]}"
do
   echo ">> $CONTAINER_REGISTRY:$RELEASE_VERSION-$i"
   if $USE_LOCAL_IMAGES ; then
    kind load docker-image  $CONTAINER_REGISTRY:$RELEASE_VERSION-$i --name $ClusterName
   fi
done


#install loki
sh install-loki.sh

#install hipster application
sh install-hipster-shop.sh



echo "SUCCESS.."