# SRE-Playground

## Background
This repository is a playground for SRE and reliable monitoring setup for demo purpose. 
E2E solution runs in local on k8 clusters provisioned with kind.


## Tools requirement
```
1. Docker
2. Kind

```

### Application
- [x] [hipster](/apps/hipster-shop-app/) ([chart-source](https://github.com/open-telemetry/opentelemetry-demo))

### Testing
- [x] load testing
  - [x] hipster
- [x] chaos testing
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
    - [ ] simple-app   


## Golden signal correlation 
<img width="1441" alt="image" src="https://user-images.githubusercontent.com/49343621/200201465-6b71783e-2003-4051-853e-83ee68e7211d.png">


## Easy Navigation from Log > Traces
<img width="1419" alt="image" src="https://user-images.githubusercontent.com/49343621/200201656-b82a4d02-23a1-4122-b4fe-efbe81a87dca.png">


## Installation

### 1. Seting up DNS

There are two options here. First using [DNSMASQ](https://thekelleys.org.uk/dnsmasq/doc.html) for DNS resolution. It helps in avoiding host file entries update. Or you can use traditional ways of updating hostfile entries.

#### Option 1.1: Install and configure DNSMASQ
```
  # The script installs dnsmasq and registers a local dns server "sreplayground.local"
  ./dns/setup.sh
```

#### Option 1.2: Add host file entries
```
command: sudo vi /etc/hosts
entries:
127.0.0.1 demo.sreplayground.local
127.0.0.1 grafana.sreplayground.local
127.0.0.1 prometheus.sreplayground.local
127.0.0.1 loadgen.sreplayground.local
127.0.0.1 chaostest.sreplayground.local
127.0.0.1 tracing.sreplayground.local
```

### 2. Clone the repo in local
```
  git clone 
```

### 3. Execute the installtion script
```
./trigger-install.sh
```
### 4. Accessing the sites:

### hipster playground UI
[demo.sreplayground.local](http://demo.sreplayground.local/)
### grafana UI
[grafana.sreplayground.local](http://grafana.sreplayground.local/)
```
User ID: admin
Password: prom-operator
```
### prometheus UI
[prometheus.sreplayground.local](http://prometheus.sreplayground.local/)
### loadtest UI
[loadgen.sreplayground.local](http://loadgen.sreplayground.local/)
### chaos-mesh UI
[chaostest.sreplayground.local](http://chaostest.sreplayground.local/)
```
# Generate user access token
 kubectl -n chaos-mesh create token chaos-dashboard

# Trigger testing 
kubectl apply -f chaos-mesh/workflows/chaos-workflow.yaml
kubectl apply -f chaos-mesh/experiments/pod-faults/container-kill.yaml
```
### tracing tool: jaeger UI
[tracing.sreplayground.local](http://tracing.sreplayground.local/)

### 5. Reseting the cluster
```
./trigger-reset.sh
(Note: Control plane components and CNI will not be deleted)
```

### 6. Deleting the cluster
```
./trigger-teardown.sh
```