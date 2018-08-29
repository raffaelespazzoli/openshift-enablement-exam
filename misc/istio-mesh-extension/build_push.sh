#!/usr/bin/env bash
docker build -t quay.io/raffaelespazzoli/istio-mesh-extension:latest .
docker push quay.io/raffaelespazzoli/istio-mesh-extension:latest