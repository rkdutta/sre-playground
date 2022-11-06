#!/bin/bash

#kind delete clusters sre-demo-site
kind create cluster --config kind/kind-cluster-1.yaml --name sre-demo-site

clear
# checking kubernetes status
until kubectl get sa default 2>&1 > /dev/null; do
  echo "Waiting for Kubernetes to start..."
  sleep 1
done
echo " `date` >>>>> kubernetes started..."

# verifying if coreDNS pods are up and running
until kubectl -n kube-system describe deployments.apps coredns | grep "0 unavailable"; do
  kubectl -n kube-system rollout restart deployment coredns
  echo "Waiting for coredns pods to start.."
  sleep 20
done

clear
echo "`date` >>>>> coreDNS started..."
echo "`date` >>>>> cluster created successfully..."