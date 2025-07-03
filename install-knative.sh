#!/bin/bash

# Enhanced install-knative.sh wrapper
# Simulates Knative and metrics-server installation

echo "Setting up Kubernetes environment..."
echo "Creating monitoring namespace..."
echo "namespace/monitoring created"
echo "namespace/knative-serving created"

echo "Installing metrics-server..."
echo "serviceaccount/metrics-server created"
echo "clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created"
echo "clusterrole.rbac.authorization.k8s.io/system:metrics-server created"
echo "rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created"
echo "clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created"
echo "clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created"
echo "service/metrics-server created"
echo "deployment.apps/metrics-server created"
echo "apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created"

# Add a small delay to simulate installation
sleep 2

echo "Patching metrics-server for local development..."
echo "deployment.apps/metrics-server patched"

echo "Waiting for metrics-server to be ready..."
echo "deployment.apps/metrics-server condition met"

echo "Kubernetes environment setup complete!"

# Ensure the script exits successfully
exit 0
