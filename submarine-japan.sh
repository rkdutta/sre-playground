kubectl config use-context kind-japan

export CLUSTER_ID=japan
export CLUSTER_CIDR=10.241.0.0/16
export SERVICE_CIDR=10.111.0.0/16
export BROKER_NS=submariner-k8s-broker
export SUBMARINER_NS=submariner-operator
export SUBMARINER_PSK=UIxiLQgkQ8L
echo ">>>>>>>>>>SUBMARINER_PSK=$SUBMARINER_PSK"

kubectl label node japan-control-plane "submariner.io/gateway=true"

helm repo add submariner-latest https://submariner-io.github.io/submariner-charts/charts

kubectl get clusters.submariner.io -A

echo $SUBMARINER_PSK
echo $SUBMARINER_BROKER_CA
echo $SUBMARINER_BROKER_TOKEN
echo $SUBMARINER_BROKER_URL

helm upgrade --install submariner-operator submariner-latest/submariner-operator \
        --create-namespace \
        --namespace "${SUBMARINER_NS}" \
        --set ipsec.psk="${SUBMARINER_PSK}" \
        --set broker.server="${SUBMARINER_BROKER_URL}" \
        --set broker.token="${SUBMARINER_BROKER_TOKEN}" \
        --set broker.namespace="${BROKER_NS}" \
        --set broker.ca="${SUBMARINER_BROKER_CA}" \
        --set submariner.serviceDiscovery=true \
        --set submariner.cableDriver=libreswan \
        --set submariner.clusterId="${CLUSTER_ID}" \
        --set submariner.clusterCidr="${CLUSTER_CIDR}" \
        --set submariner.serviceCidr="${SERVICE_CIDR}" \
        --set submariner.natEnabled="true" \
        --set serviceAccounts.lighthouseAgent.create=true \
        --set serviceAccounts.lighthouseCoreDns.create=true

kubectl get clusters.submariner.io -A


