#!/usr/bin/env bash

set -o errexit
docker build -t quay.io/raffaelespazzoli/istio-mesh-extension:latest .
docker push quay.io/raffaelespazzoli/istio-mesh-extension:latest