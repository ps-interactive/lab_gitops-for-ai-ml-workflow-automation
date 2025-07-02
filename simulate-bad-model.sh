#!/bin/bash

echo "Simulating deployment of a faulty model..."

# Update deployment to simulate a bad model
echo "Deploying faulty model version..."
kubectl set env deployment/ml-predictor \
  MODEL_VERSION=bad-1.0 \
  SIMULATE_ERROR=true \
  ERROR_RATE=0.8

# Add annotation to track this as a bad deployment
kubectl annotate deployment/ml-predictor \
  rollback.reason="simulated-failure" \
  rollback.enabled="true" \
  --overwrite

echo "Faulty model deployed. Rollback should trigger automatically."
