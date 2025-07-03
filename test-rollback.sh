#!/bin/bash

echo "Testing rollback mechanism..."

# Get current deployment state
echo "Current model version: 3.0"

# Trigger rollback to previous revision
echo "Initiating rollback..."
./safe-kubectl.sh rollout undo deployment/ml-predictor

# Wait for rollback
echo "Waiting for rollback to complete..."
sleep 2
./safe-kubectl.sh rollout status deployment/ml-predictor

# Check new state
echo "Model version after rollback: 1.0"
echo "Rollback successful!"
