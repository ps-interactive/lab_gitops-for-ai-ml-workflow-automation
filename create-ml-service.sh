#!/bin/bash

echo "Creating ML prediction service..."

# Create ML service Dockerfile
cat > Dockerfile.ml << 'EOF'
FROM python:3.9-slim

WORKDIR /app

RUN pip install flask numpy scikit-learn

COPY ml-server.py .

CMD ["python", "ml-server.py"]
EOF

# Create ML server application
cat > ml-server.py << 'EOF'
from flask import Flask, request, jsonify
import numpy as np
import os

app = Flask(__name__)

MODEL_VERSION = os.environ.get('MODEL_VERSION', '1.0')

@app.route('/')
def health():
    return jsonify({"status": "healthy", "model_version": MODEL_VERSION})

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        features = np.array(data['features'])
        # Simple mock prediction
        prediction = float(np.sum(features) * 0.5)
        return jsonify({
            "prediction": prediction,
            "model_version": MODEL_VERSION,
            "status": "success"
        })
    except Exception as e:
        return jsonify({"error": str(e), "status": "failed"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Build Docker image
docker build -f Dockerfile.ml -t ml-predictor:latest .

# Create Knative service YAML
cat > ml-service.yaml << 'EOF'
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: ml-predictor
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "1"
        autoscaling.knative.dev/maxScale: "10"
    spec:
      containers:
        - image: ml-predictor:latest
          imagePullPolicy: Never
          env:
            - name: MODEL_VERSION
              value: "1.0"
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
EOF

# Import the image into k3d
k3d image import ml-predictor:latest -c ml-cluster

echo "ML service created successfully!"
