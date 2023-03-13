# SRE-Playground

This repository is a playground for SRE and reliable monitoring setup for demo purpose. 
E2E solution runs in local k8 clusters provisioned with kind.

# Features
### Kubernetes Cluster
- [x] kind
  - [x] with kube-proxy
    - [x] x86_64
    - [x] arm64 (apple mac m1 chips)
  - [x] without kube-proxy
    - [ ] cilium/eBPF
      - [ ] x86_64
      - [x] arm64 (apple mac m1 chips)
### Demo Application
- [x] [hipster](/apps/hipster-shop-app/) ([chart-source](https://github.com/open-telemetry/opentelemetry-demo))
### Logging
- [x] fluent-bit :arrow_right: Loki
    - [x] with kube-proxy
    - [ ] without kube-proxy
- [x] Loki
### Traces
- [ ] OpenTelemetry :arrow_right: Jaeger
  - [x] workload traces
  - [ ] kubernetes controleplane traces
### Metrics
- [x] Prometheus
  - [x] kubernetes components metrics
  - [x] workload metrics
  - [x] node metrics
### Ingress
- [x] nginx-ingress
  - [x] with kube-proxy
  - [ ] without kube-proxy
- [ ] cilium
  - [ ] with kube-proxy
  - [x] without kube-proxy
### Loadbalancer
- [x] Metallb
### Testing
- [x] load testing
  - [x] hipster
- [x] chaos testing
  - [ ] gremlin
  - [x] [chaos-mesh](/chaosmesh/experiments/)
    - [x] hipster
      - [x] [network-faults](/chaosmesh/experiments/network-faults/)
        - [x] bandwidth trip
        - [x] delay
        - [x] partition
      - [x] [pod-faults](/chaosmesh/experiments/pod-faults/)
        - [x] container kill
        - [x] pod failure
        - [x] pod kill
      - [x] [stress-conditions](/chaosmesh/experiments/stress-conditions/)
        - [x] cpu stress
        - [x] memory stress  

### Golden signal correlation 
<img width="1441" alt="image" src="https://user-images.githubusercontent.com/49343621/200201465-6b71783e-2003-4051-853e-83ee68e7211d.png">


### Navigation from Logs to Traces
<img width="1419" alt="image" src="https://user-images.githubusercontent.com/49343621/200201656-b82a4d02-23a1-4122-b4fe-efbe81a87dca.png">


# Tools & software requirement
```
1. Docker
2. Kind
3. kubectl
4. helm
```


# Installation

### 1. Seting up DNS

There are two options here (Option 1.1 & 1.2). First using [DNSMASQ](https://thekelleys.org.uk/dnsmasq/doc.html) for DNS resolution. It helps in avoiding host file entries update. Or you can use traditional ways of updating hostfile entries.

#### Option 1.1: Install and configure DNSMASQ
```
  # The script installs dnsmasq and registers a local dns server "sre-playground.devops.nakednerds.net"
  ./dns/setup.sh
```

#### Option 1.2: Add host file entries
```
command: sudo vi /etc/hosts
entries:
127.0.0.1 demo.sre-playground.devops.nakednerds.net
127.0.0.1 grafana.sre-playground.devops.nakednerds.net
127.0.0.1 prometheus.sre-playground.devops.nakednerds.net
127.0.0.1 chaostest.sre-playground.devops.nakednerds.net
```

### 2. Clone the repo in local
```
  git clone https://github.com/rkdutta/sre-playground.git
```

### 3. Execute the installtion script
```
./bootstrap.sh
```


# UI Access (on local port 80)
## hipster playground
[demo.sre-playground.devops.nakednerds.net](http://demo.sre-playground.devops.nakednerds.net/)
## grafana
[grafana.sre-playground.devops.nakednerds.net](http://grafana.sre-playground.devops.nakednerds.net/)
```
User ID: admin
Password: prom-operator
```
## prometheus
[prometheus.sre-playground.devops.nakednerds.net](http://prometheus.sre-playground.devops.nakednerds.net/)
## loadtest
[demo.sre-playground.devops.nakednerds.net/loadgen/](http://demo.sre-playground.devops.nakednerds.net/loadgen/)
## tracing: jaeger
[demo.sre-playground.devops.nakednerds.net/jaeger/](http://demo.sre-playground.devops.nakednerds.net/jaeger/ui/)
## chaos-mesh
[chaostest.sre-playground.devops.nakednerds.net](http://chaostest.sre-playground.devops.nakednerds.net/)
```
# Generate user access token
 kubectl -n platform create token chaos-dashboard

# Trigger testing 
kubectl apply -f chaos-mesh/workflows/chaos-workflow.yaml
kubectl apply -f chaos-mesh/experiments/pod-faults/container-kill.yaml
```


# Reseting the cluster
```
./reset.sh
(Note: Control plane components and CNI will not be deleted)
```

# Deleting the cluster
```
./teardown.sh
```