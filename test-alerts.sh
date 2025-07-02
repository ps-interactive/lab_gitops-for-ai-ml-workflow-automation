#!/bin/bash

echo "Testing alert system..."

# Create a mock alert
cat > test-alert.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-alert
  labels:
    type: alert
data:
  alert: |
    {
      "name": "ModelAccuracyLow",
      "severity": "critical",
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "model": "ml-predictor",
      "accuracy": 0.85,
      "threshold": 0.90,
      "status": "firing"
    }
EOF

# Apply the test alert
kubectl apply -f test-alert.yaml

echo "Test alert created. Checking alerts..."

# List all alerts
kubectl get configmap -l type=alert -o json | jq '.items[].data.alert' -r | jq .

echo "Alert test complete!"
