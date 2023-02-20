ClusterName=$1

helm repo add cilium https://helm.cilium.io/
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

# verify Masquerading
kubectl -n kube-system exec ds/cilium -- cilium status | grep Masquerading