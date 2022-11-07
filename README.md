# SRE-Playground

## Background
This repository is a playground for SRE and reliable monitoring setup for demo purpose. E2E solution runs in local on kind k8 clusters. 


## Tools requirement
```
1. Docker
2. Kind

```

### Infrastructure
- [x] Two node cluster with Kubernetes v1.25
- [x] Distributed and reliable open-telemetry(Otel) setup
- [x] Prometheus (for metrics via Otel)
- [x] Loki (for logs via fluent-bit)
- [x] Jaeger (for tracing via Otel)
- [x] ElasticSearch for traces storage
- [x] Jaeger & ElasticSearch integration
- [x] Out-of-the-box auto-instrumentation using OpenTelemetry
- [x] Trace collection using Otel
- [x] Metric collection using Otel
- [x] Grafana startup with custom datasources(prometheus,loki,jaeger)
- [x] Golden signal correlation in Grafana (Metric -> Log -> Traces)
- [x] Generate and collect custom metrics (visits_total)
- [ ] Logs collection using Otel
- [ ] Security
- [ ] Ingress

### Application
- [x] simple-app (two spring-boot microservices) 
  - [x] [frontend api](https://github.com/rkdutta/otel-demo-api-service)
  - [x] [backend api](https://github.com/rkdutta/otel-demo-customer-service)
  
- [ ] hipster

### Testing
- [x] load testing
  - [x] simple-app
  - [ ] hipster
- [ ] chaos testing
  - [ ] simple-app
  - [ ] hipster   


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
./install-e2e.sh
```
### 3. To obtain UI access:
```
./port-fwd.sh
```
## Uninstallation Steps
```
./teardown.sh
```
