#!/bin/bash

echo "Generating test traffic for anomaly detection..."

# Set up port-forward to access the service
kubectl port-forward svc/ml-predictor 8888:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 2

SERVICE_URL="http://localhost:8888"
echo "Sending requests to: $SERVICE_URL"

# Generate normal traffic
for i in {1..10}; do
    echo "Sending normal request $i..."
    curl -s -X POST "${SERVICE_URL}/predict" \
      -H "Content-Type: application/json" \
      -d "{\"features\": [$(shuf -i 1-10 -n 1).0, $(shuf -i 1-10 -n 1).0, $(shuf -i 1-10 -n 1).0]}" || true
    sleep 0.5
done

# Generate anomalous traffic
echo ""
echo "Generating anomalous patterns..."
for i in {1..5}; do
    echo "Sending anomalous request $i..."
    curl -s -X POST "${SERVICE_URL}/predict" \
      -H "Content-Type: application/json" \
      -d "{\"features\": [999.0, 999.0, 999.0]}" || true
    sleep 0.1
done

# Clean up port-forward
kill $PF_PID 2>/dev/null

echo ""
echo "Traffic generation complete!"
