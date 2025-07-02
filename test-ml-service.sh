#!/bin/bash

echo "Testing ML prediction service..."

# Get service URL
SERVICE_URL=$(kubectl get ksvc ml-predictor -o jsonpath='{.status.url}')

# Test health endpoint
echo "Testing health endpoint..."
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- \
  curl -s "${SERVICE_URL}/"

echo ""
echo "Testing prediction endpoint..."

# Test prediction endpoint
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- \
  curl -s -X POST "${SERVICE_URL}/predict" \
  -H "Content-Type: application/json" \
  -d '{"features": [1.2, 3.4, 5.6, 7.8]}'

echo ""
echo "ML service test complete!"
