#!/bin/bash

(kubectl port-forward svc/hipster-shop-frontendproxy 8080:8080) &
(kubectl port-forward svc/kiali 20001:20001 -n istio-system) &
