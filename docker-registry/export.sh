kubectl -n docker-registry get secrets docker-registry-client-tls -o=jsonpath={.data."ca\.crt"} | base64 -d > ca.crt
kubectl -n docker-registry get secrets docker-registry-client-tls -o=jsonpath={.data."tls\.crt"} | base64 -d > tls.crt
kubectl -n docker-registry get secrets docker-registry-client-tls -o=jsonpath={.data."tls\.key"} | base64 -d > tls.key