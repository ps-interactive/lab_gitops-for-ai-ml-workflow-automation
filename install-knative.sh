#!/bin/bash

echo "Setting up Kubernetes environment..."

# Create a namespace for ML workloads
kubectl create namespace ml-ops --dry-run=client -o yaml | kubectl apply -f -

# Install metrics-server for resource monitoring (lightweight alternative)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics-server to work with insecure TLS
kubectl patch -n kube-system deployment metrics-server --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "Waiting for metrics-server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

echo "Kubernetes environment setup complete!"
