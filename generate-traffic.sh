#!/bin/bash

echo "Generating test traffic for anomaly detection..."

# Get service URL
SERVICE_URL=$(kubectl get ksvc ml-predictor -o jsonpath='{.status.url}' 2>/dev/null || echo "http://ml-predictor.default.svc.cluster.local")

echo "Sending requests to: $SERVICE_URL"

# Generate normal traffic
for i in {1..10}; do
    echo "Sending normal request $i..."
    kubectl run -it --rm traffic-gen-$i --image=curlimages/curl --restart=Never -- \
      curl -s -X POST "${SERVICE_URL}/predict" \
      -H "Content-Type: application/json" \
      -d "{\"features\": [$(shuf -i 1-10 -n 1).0, $(shuf -i 1-10 -n 1).0, $(shuf -i 1-10 -n 1).0]}" || true &
    sleep 1
done

# Wait for normal traffic to complete
wait

# Generate anomalous traffic
echo "Generating anomalous patterns..."
for i in {1..5}; do
    echo "Sending anomalous request $i..."
    kubectl run -it --rm anomaly-gen-$i --image=curlimages/curl --restart=Never -- \
      curl -s -X POST "${SERVICE_URL}/predict" \
      -H "Content-Type: application/json" \
      -d "{\"features\": [999.0, 999.0, 999.0]}" || true &
    sleep 0.1
done

wait
echo "Traffic generation complete!"
