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


KUBEPROXY_OPTS=${3:-"with-kubeproxy"}
CNI=${2:-"cilium"}
CLUSTER_NAME=${1:-"sre-playground"}


KIND_CONFIG_FILE=`mktemp`
OVERRIDE_CONFIG_FILE=`mktemp`
PLAYGROUND_CONFIG_FILE=`mktemp`

CPU_ARCH="$(uname -m)"
PLAYGROUND_CONFIG_FILE_URI="kind/bootstrap-config.yaml"

# reading the raw bootstrap config file and resolve the aliases
yq 'explode(.)' $PLAYGROUND_CONFIG_FILE_URI > $PLAYGROUND_CONFIG_FILE

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

#install the cluster
DEPLOYMENT=sreplayground-cluster
RELEASE=$CLUSTER_NAME-cluster
kubectl create namespace $RELEASE --dry-run=client -o yaml | kubectl apply -f -
helm dependency update $DEPLOYMENT
helm upgrade --install $RELEASE $DEPLOYMENT \
--dependency-update   \
--namespace kube-system \
--set metallb.addresspool=$METALLB_IP_RANGE --wait \
--set $CNI.enabled=true \
--set cilium.k8sServiceHost=$CLUSTER_NAME-control-plane \
--set cilium.ipMasqAgent.enabled=$(yq .ipMasqAgent.enabled $OVERRIDE_CONFIG_FILE) \
--set cilium.kubeProxyReplacement=$(yq .kubeProxyReplacement $OVERRIDE_CONFIG_FILE) \
--set cilium.hubble.ui.ingress.hosts[0]="hubble.$CLUSTER_NAME.devops.nakednerds.net" \
--set opentelemetry-collector.config.exporters.otlp.endpoint="$CLUSTER_NAME-platform-otel-collector-hub.$CLUSTER_NAME-platform.svc.cluster.local:4317"


# TO BE DISCUSSED BEFORE ENABLING ISTIO
#install istio and kiali 
#(cd istio && ./istio.sh)

STORAGE_CONFIG_FILE=`mktemp`
STORAGE_CONFIG_FILE_TEMPLATE="sreplayground-platform/files/thanos-storage-config.yaml"
export STORAGE_ACCOUNT_NAME="thanosstorage0"
export STORAGE_ACCOUNT_KEY=$STORAGE_ACCOUNT_KEY
export STORAGE_ACCOUNT_CONTAINER_NAME=$CLUSTER_NAME
yq '.config.storage_account_key=env(STORAGE_ACCOUNT_KEY) | .config.storage_account=env(STORAGE_ACCOUNT_NAME) | .config.container=env(STORAGE_ACCOUNT_CONTAINER_NAME)' $STORAGE_CONFIG_FILE_TEMPLATE > $STORAGE_CONFIG_FILE
cat $STORAGE_CONFIG_FILE


# install platform components
DEPLOYMENT=sreplayground-platform
RELEASE=$CLUSTER_NAME-platform
kubectl create namespace $RELEASE --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic $RELEASE-thanos-storage-connection-string \
  --from-file=thanos.yaml=$STORAGE_CONFIG_FILE \
  --namespace $RELEASE \
  --dry-run=client -o yaml | kubectl apply -f -

helm dependency update $DEPLOYMENT
helm upgrade --install  $RELEASE $DEPLOYMENT \
--namespace $RELEASE \
--create-namespace \
--set global.clusterName=$CLUSTER_NAME \
--set jaeger-operator.clusterName=$CLUSTER_NAME \
--set kube-prometheus-stack.grafana.ingress.hosts[0]="grafana.$CLUSTER_NAME.devops.nakednerds.net" \
--set kube-prometheus-stack.prometheus.ingress.hosts[0]="prometheus.$CLUSTER_NAME.devops.nakednerds.net" \
--set kube-prometheus-stack.prometheus.prometheusSpec.thanos.objectStorageConfig.name="$RELEASE-thanos-storage-connection-string" \
--set kube-prometheus-stack.prometheus.prometheusSpec.externalLabels.cluster_name="$CLUSTER_NAME" \
--set-file thanos.objstoreConfig=$STORAGE_CONFIG_FILE \
--wait


# install hipstershop
DEPLOYMENT=sreplayground-hipstershop
RELEASE=$CLUSTER_NAME-hipstershop
helm dependency update $DEPLOYMENT
kubectl create namespace $RELEASE --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install  $RELEASE $DEPLOYMENT \
--namespace $RELEASE \
--create-namespace \
--set opentelemetry-demo.components.frontendProxy.ingress.hosts[0].host="hipstershop.$CLUSTER_NAME.devops.nakednerds.net" \
--set opentelemetry-demo.components.frontendProxy.ingress.hosts[0].paths[0].path="/" \
--set opentelemetry-demo.components.frontendProxy.ingress.hosts[0].paths[0].pathType="Prefix" \
--set opentelemetry-demo.components.frontendProxy.ingress.hosts[0].paths[0].port="8080" \
--set opentelemetry-demo.opentelemetry-collector.config.exporters.otlp.endpoint="$CLUSTER_NAME-platform-otel-collector-hub.$CLUSTER_NAME-platform.svc.cluster.local:4317" \
--set ingress.components[0].name="index-page" \
--set ingress.components[0].rules[0].host="$CLUSTER_NAME.devops.nakednerds.net" \
--set ingress.components[0].rules[0].http.paths[0].path="/" \
--set ingress.components[0].rules[0].http.paths[0].pathType="Prefix" \
--set ingress.components[0].rules[0].http.paths[0].backend.service.name="$RELEASE-dark-index-page" \
--set ingress.components[0].rules[0].http.paths[0].backend.service.port.number="8080" \
--set ingress.components[1].name="otel" \
--set ingress.components[1].rules[0].host="otel.$RELEASE.devops.nakednerds.net" \
--set ingress.components[1].rules[0].http.paths[0].path="/v1/traces" \
--set ingress.components[1].rules[0].http.paths[0].pathType="Prefix" \
--set ingress.components[1].rules[0].http.paths[0].backend.service.name="$RELEASE-otelcol" \
--set ingress.components[1].rules[0].http.paths[0].backend.service.port.number="4318" 

# install testing
DEPLOYMENT=sreplayground-testing
RELEASE=$CLUSTER_NAME-testing
kubectl create namespace $RELEASE --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install  $RELEASE $DEPLOYMENT \
--namespace $RELEASE \
--create-namespace \
--set chaos-mesh.dashboard.ingress.hosts[0].name="chaostest.$CLUSTER_NAME.devops.nakednerds.net"

echo "SUCCESS.."

