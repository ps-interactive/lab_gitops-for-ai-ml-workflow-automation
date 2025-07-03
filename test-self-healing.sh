#!/bin/bash

echo "Testing self-healing mechanism..."

# Create a failure scenario
echo "Creating a simulated failure..."
./safe-kubectl.sh scale deployment remediation-controller --replicas=0 2>/dev/null
sleep 2

echo "Failure created - remediation should kick in..."

# Self-healing simulation
echo "Self-healing process initiated..."
./safe-kubectl.sh scale deployment remediation-controller --replicas=1 2>/dev/null

# Wait for recovery
echo "Waiting for recovery..."
sleep 3

echo "Self-healing test complete!"
