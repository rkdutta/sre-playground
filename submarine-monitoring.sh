
kubectl config use-context kind-monitoring

export CLUSTER_ID=monitoring
export CLUSTER_CIDR=10.240.0.0/16
export SERVICE_CIDR=10.110.0.0/16
export BROKER_NS=submariner-k8s-broker
export SUBMARINER_NS=submariner-operator
export SUBMARINER_PSK=UIxiLQgkQ8L
#export SUBMARINER_PSK=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 64 | head -n 1)
echo ">>>>>>>>>>SUBMARINER_PSK=$SUBMARINER_PSK"

kubectl label node monitoring-control-plane "submariner.io/gateway=true"

helm repo add submariner-latest https://submariner-io.github.io/submariner-charts/charts
helm upgrade --install "${BROKER_NS}" submariner-latest/submariner-k8s-broker \
             --create-namespace \
             --namespace "${BROKER_NS}"

export SUBMARINER_BROKER_CA=$(kubectl -n "${BROKER_NS}" get secrets \
    -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='${BROKER_NS}-client')].data['ca\.crt']}")

export SUBMARINER_BROKER_TOKEN=$(kubectl -n "${BROKER_NS}" get secrets \
    -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='${BROKER_NS}-client')].data.token}" \
       | base64 --decode)

export SUBMARINER_BROKER_URL=$(kubectl -n default get endpoints kubernetes \
    -o jsonpath="{.subsets[0].addresses[0].ip}:{.subsets[0].ports[?(@.name=='https')].port}")

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

