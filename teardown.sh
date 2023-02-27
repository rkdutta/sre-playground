#!/bin/bash
set -e

ClusterName="sre-demo-site"
kind delete clusters $ClusterName