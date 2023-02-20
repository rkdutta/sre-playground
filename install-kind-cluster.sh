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

# verifying if the kind cluster system pods are up and running
#if kubectl -n kube-system get pods -o custom-columns=POD:.metadata.name,STATUS:.status.phase --no-headers
# if kubectl -n kube-system get pods -o custom-columns=POD:.metadata.name,STATUS:.status.phase | grep -i running; do
#   echo "`date` INFO cluster exists. Skiping reinstall.."
# else
# fi

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
helm upgrade \
    --install cilium cilium/cilium \
    --namespace kube-system \
    --set image.pullPolicy=IfNotPresent \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=$ClusterName-control-plane \
    --set k8sServicePort=6443 \
    --set bpf.masquerade=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set hubble.tls.auto.enabled=true \
    --set hubble.tls.auto.method=helm \
    --reuse-values \
    --set ipMasqAgent.enabled=true \
    --set prometheus.enabled=true \
    --set operator.prometheus.enabled=true \
    --set hubble.enabled=true \
    --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}"


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



#install hipster application
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade --install \
 hipster-shop open-telemetry/opentelemetry-demo \
 --namespace "hipster-shop" \
 --create-namespace \
 --values apps/hipster-shop-app/values.yaml


echo "SUCCESS.."