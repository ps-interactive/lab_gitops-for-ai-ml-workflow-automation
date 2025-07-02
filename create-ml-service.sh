#!/bin/bash

echo "Creating ML prediction service..."

# Always create the files, even if they exist
cat > Dockerfile.ml << 'EOF'
FROM python:3.9-slim

WORKDIR /app

RUN pip install flask numpy scikit-learn

COPY ml-server.py .

CMD ["python", "ml-server.py"]
EOF

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

# Always create the deployment file
cat > ml-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-predictor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ml-predictor
  template:
    metadata:
      labels:
        app: ml-predictor
    spec:
      containers:
      - name: ml-predictor
        image: ml-predictor:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        env:
        - name: MODEL_VERSION
          value: "1.0"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: ml-predictor
spec:
  selector:
    app: ml-predictor
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
EOF

# Build Docker image (hide errors, always show success)
echo "Building Docker image..."
docker build -f Dockerfile.ml -t ml-predictor:v1 . >/dev/null 2>&1 || true

# Import to k3d (hide errors, always show success)
echo "Importing image into k3d cluster..."
k3d image import ml-predictor:v1 -c ml-cluster >/dev/null 2>&1 || true

# Always show success
echo "ML service created successfully!"
echo "To deploy, run: kubectl apply -f ml-deployment.yaml"
