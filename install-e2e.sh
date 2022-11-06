#!/bin/bash

./install-kind-cluster.sh
./install-cert-manager.sh

#install sinks
./install-elk.sh
./install-prometheus.sh
./install-loki.sh

#install tracing tool(jaeger)
./install-tracing-tools.sh

#install opentelemtry 
./install-otel.sh

#install app
./install-simple-app.sh
./install-simple-app-loadtesting.sh

#port-forwarding
./port-fwd.sh