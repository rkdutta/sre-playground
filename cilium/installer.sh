ClusterName=sre-demo-site-control-plane
EnableHubbleSwitch=$2
namespace=$3

# namespace=kube-system
# ClusterName="sre-demo-site"
# EnableHubbleSwitch=false

#LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

#installing cilium
helm repo add cilium https://helm.cilium.io/
helm upgrade \
    --install cilium cilium/cilium \
    --namespace $namespace \
    --values values.yaml \
    --set k8sServiceHost=$ClusterName

   # --set hubble.ui.enabled=$EnableHubbleSwitch \
   # --set hubble.ui.ingress.hosts[0]="hubble-ui.${LB_IP}.nip.io" \

echo "`date` >>>>> wait for cilium to be ready"
kubectl wait --namespace $namespace \
                --for=condition=ready pod \
                --selector=k8s-app=cilium \
                --timeout=90s

# verify Masquerading
kubectl -n kube-system exec ds/cilium -- cilium status | grep Masquerading

