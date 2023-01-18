helm repo add chaos-mesh https://charts.chaos-mesh.org
helm search repo chaos-mesh
kubectl create ns chaos-mesh
# Default to /var/run/docker.sock
#helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh --version 2.5.1
helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock --version 2.5.1

