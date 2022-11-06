#!/bin/bash

clear
port_fwd()
{
    echo 
    echo 
    echo $SVC_NAME
    echo '=============================='
    if [[ $(lsof -t -i:${SVC_PORT}) ]]; then kill -9 $(lsof -t -i:${SVC_PORT}); fi
    kubectl -n ${SVC_NAMESPACE} port-forward ${SVC_NAME} ${SVC_PORT}:${MAPPED_PORT}  >/dev/null &
    echo "Access ${SVC_NAMESPACE}/${SVC_NAME} @ http://localhost:${SVC_PORT}/" 
    
}


#jaeger
SVC_PORT="16686"
MAPPED_PORT="80"
SVC_NAMESPACE="observability"
SVC_NAME="svc/jaeger-query"
port_fwd


# elastic search
SVC_PORT="9200"
MAPPED_PORT="9200"
SVC_NAMESPACE="elasticsearch"
SVC_NAME="svc/elasticsearch-es-http"
port_fwd
PASSWORD=$(kubectl -n $SVC_NAMESPACE get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
echo "elasticsearch credentials: elastic / $PASSWORD"


# kibana
SVC_PORT="5601"
MAPPED_PORT="5601"
SVC_NAMESPACE="elasticsearch"
SVC_NAME="svc/kibana"
port_fwd
PASSWORD=$(kubectl -n $SVC_NAMESPACE get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
echo "elasticsearch credentials: elastic / $PASSWORD"



# prometheus-grafana
SVC_PORT="3005"
MAPPED_PORT="80"
SVC_NAMESPACE="prometheus"
SVC_NAME="svc/prometheus-grafana"
port_fwd
echo "prometheus credentials: admin/prom-operator"


# prometheus-prom
SVC_PORT="9090"
MAPPED_PORT="9090"
SVC_NAMESPACE="prometheus"
SVC_NAME="svc/prometheus-kube-prometheus-prometheus"
port_fwd


SVC_PORT="3000"
MAPPED_PORT="80"
SVC_NAMESPACE="loki-stack"
SVC_NAME="svc/loki-grafana"
port_fwd
PASSWORD=$(kubectl get secret --namespace $SVC_NAMESPACE loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)
echo "Loki credentials: admin / $PASSWORD"


#kiali
SVC_PORT="20001"
MAPPED_PORT="20001"
SVC_NAMESPACE="istio-system"
SVC_NAME="svc/kiali"
#port_fwd

