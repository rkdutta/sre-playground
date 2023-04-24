kubectl -n chartmuseum get secrets chartmuseum-client-tls -o=jsonpath={.data."ca\.crt"} | base64 -d > ca.crt
kubectl -n chartmuseum get secrets chartmuseum-client-tls -o=jsonpath={.data."tls\.crt"} | base64 -d > tls.crt
kubectl -n chartmuseum get secrets chartmuseum-client-tls -o=jsonpath={.data."tls\.key"} | base64 -d > tls.key