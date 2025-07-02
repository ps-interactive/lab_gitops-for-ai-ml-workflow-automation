#!/bin/bash

VERSION=${1:-"1.0"}
ACCURACY=${2:-"0.95"}
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "Registering model version $VERSION with accuracy $ACCURACY..."

# Create or update model registry
if [ ! -f "model-registry.json" ]; then
    echo '{"models": []}' > model-registry.json
fi

# Add new model entry
jq --arg v "$VERSION" --arg a "$ACCURACY" --arg t "$TIMESTAMP" \
  '.models += [{
    "version": $v,
    "accuracy": ($a | tonumber),
    "timestamp": $t,
    "status": "active",
    "location": ("minio://ml-models/model-v" + $v + ".json")
  }]' model-registry.json > tmp.json && mv tmp.json model-registry.json

echo "Model registered successfully!"
cat model-registry.json | jq .
