#!/bin/bash
set -e

clusterName=${1:-"sre-playground"}
kind delete clusters $clusterName