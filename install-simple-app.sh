#!/bin/bash

# install simple app
helm upgrade --install \
 simple-app apps/simple-app \
 --dependency-update \
 --atomic \
 --wait \
 --timeout=10m0s 