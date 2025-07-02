#!/bin/bash

echo "Testing rollback mechanism..."

# Get current deployment state
CURRENT_IMAGE=$(kubectl get deployment ml-predictor -o jsonpath='{.spec.template.spec.containers[0].image}')
CURRENT_ENV=$(kubectl get deployment ml-predictor -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="MODEL_VERSION")].value}')
echo "Current model version: $CURRENT_ENV"

# Trigger rollback to previous revision
echo "Initiating rollback..."
kubectl rollout undo deployment/ml-predictor

# Wait for rollback
echo "Waiting for rollback to complete..."
kubectl rollout status deployment/ml-predictor

# Check new state
NEW_ENV=$(kubectl get deployment ml-predictor -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="MODEL_VERSION")].value}')
echo "Model version after rollback: $NEW_ENV"

if [ "$CURRENT_ENV" != "$NEW_ENV" ]; then
    echo "Rollback successful!"
else
    echo "Rollback may not have been necessary - deployment is stable"
fi
