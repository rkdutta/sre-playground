#!/bin/bash
set -e

clusterName=${1:-"sre-demo-site"}
kind delete clusters $clusterName