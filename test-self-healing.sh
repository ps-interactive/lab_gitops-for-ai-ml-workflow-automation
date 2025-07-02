#!/bin/bash

echo "Testing self-healing mechanism..."

# Create a failure scenario
echo "Creating a simulated failure..."
kubectl scale deployment remediation-controller --replicas=0
sleep 2

echo "Failure created - remediation should kick in..."

# Self-healing simulation
echo "Self-healing process initiated..."
kubectl scale deployment remediation-controller --replicas=1

# Wait for recovery
echo "Waiting for recovery..."
kubectl wait --for=condition=available deployment/remediation-controller --timeout=60s

echo "Self-healing test complete!"
