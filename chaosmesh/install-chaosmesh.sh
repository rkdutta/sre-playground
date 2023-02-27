namespace="chaos-mesh"
app="chaos-mesh"
selector="app.kubernetes.io/instance=chaos-mesh"

helm repo add chaos-mesh https://charts.chaos-mesh.org
kubectl create ns $namespace
helm upgrade \
--install $app chaos-mesh/chaos-mesh \
-n=$namespace \
--version 2.5.1 \
--set chaosDaemon.runtime=containerd \
--set chaosDaemon.socketPath=/run/containerd/containerd.sock   # Default to /var/run/docker.sock


echo "`date` >>>>> wait for chaos-mesh to be ready"
kubectl wait --namespace $namespace \
                --for=condition=ready pod \
                --selector=$selector \
                --timeout=90s

#Executing chaos experiment workflow:
kubectl apply -f chaosmesh/workflows/chaos-workflow.yaml

# create permissions for the dashboard user
kubectl apply -f chaosmesh/permissions.yaml

# generate token for the dashboard user
echo && echo
echo ">>>> CHAOS MESH DASHBOARD URL: http://chaostest.sre-playground.com/dashboard"
echo ">>>> CHAOS MESH DASHBOARD TOKEN:"
kubectl -n chaos-mesh create token chaos-dashboard