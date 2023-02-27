ClusterName=$1
EnableHubbleSwitch=$2

ClusterName=sre-demo-site-control-plane
EnableHubbleSwitch=true
namespace="kube-system"

#LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

helm repo add cilium https://helm.cilium.io/
helm upgrade \
    --install cilium cilium/cilium \
    --namespace $namespace \
    --values cilium/values.yaml \
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

