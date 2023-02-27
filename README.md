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


## Installation Steps

### 1. Clone the repo in local
```
  git clone 
```

### 2. Execute the installtion script
```
./trigger-install.sh
```
### 3. To obtain UI access:

### Step 1: Add host file entries
```
command: sudo vi /etc/hosts

entries:
127.0.0.1 demo.sre-playground.com
127.0.0.1 grafana.sre-playground.com
127.0.0.1 prometheus.sre-playground.com
127.0.0.1 loadtest.sre-playground.com
127.0.0.1 chaostest.sre-playground.com
127.0.0.1 tracing.sre-playground.com
```
### Urls:
[demo.sre-playground.com](demo.sre-playground.com)

[grafana.sre-playground.com](grafana.sre-playground.com)

[prometheus.sre-playground.com](prometheus.sre-playground.com)

[loadtest.sre-playground.com](loadtest.sre-playground.com)

[chaostest.sre-playground.com](chaostest.sre-playground.com)

[tracing.sre-playground.com](tracing.sre-playground.com)

## Reseting the cluster
```
./trigger-reset.sh
(Note: Control plane components and CNI will not be deleted)
```

## Deleting the cluster
```
./trigger-teardown.sh
```

## Chaos Testing 
```
kubectl apply -f chaos-mesh/workflows/chaos-workflow.yaml
kubectl apply -f chaos-mesh/experiments/pod-faults/container-kill.yaml
```
