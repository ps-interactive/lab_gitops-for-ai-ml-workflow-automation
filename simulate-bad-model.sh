#!/bin/bash

echo "Simulating deployment of a faulty model..."

# Create a bad model configuration
cat > bad-model.yaml << 'EOF'
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: ml-predictor
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "1"
        rollback.enabled: "true"
    spec:
      containers:
        - image: localhost:5000/ml-predictor:latest
          env:
            - name: MODEL_VERSION
              value: "bad-1.0"
            - name: SIMULATE_ERROR
              value: "true"
            - name: ERROR_RATE
              value: "0.8"
EOF

# Apply the bad configuration
echo "Deploying faulty model version..."
kubectl apply -f bad-model.yaml

echo "Faulty model deployed. Rollback should trigger automatically."
