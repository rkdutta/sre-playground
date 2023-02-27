#!/bin/bash
set -e

ClusterName="{1:-sre-demo-site}"
kind delete clusters $ClusterName