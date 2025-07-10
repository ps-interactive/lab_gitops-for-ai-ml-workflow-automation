#!/bin/bash
# GitOps ML Lab Initialization Script

echo "Initializing GitOps ML Lab..."

# Create lab directory
mkdir -p ~/gitops-lab
cd ~/gitops-lab

# Check if MinIO is already running
if docker ps | grep -q minio; then
    echo "MinIO is already running"
else
    echo "Starting MinIO..."
    docker run -d --name minio \
      -p 9000:9000 -p 9001:9001 \
      -e MINIO_ROOT_USER=minioadmin \
      -e MINIO_ROOT_PASSWORD=minioadmin \
      minio/minio server /data --console-address ":9001"
fi

# Check if ML service is already running
if docker ps | grep -q ml-service; then
    echo "ML service is already running"
else
    echo "Starting ML service..."
    docker run -d --name ml-service \
      -p 5000:5000 \
      python:3.9-slim \
      sh -c "pip install flask && python -c '
from flask import Flask, jsonify, request
import os
app = Flask(__name__)
MODEL_VERSION = os.getenv(\"MODEL_VERSION\", \"1.0.0\")

@app.route(\"/health\")
def health():
    return jsonify({\"status\": \"healthy\", \"version\": MODEL_VERSION})

@app.route(\"/predict\", methods=[\"POST\"])
def predict():
    return jsonify({\"prediction\": \"class_a\", \"confidence\": 0.95})

if __name__ == \"__main__\":
    app.run(host=\"0.0.0.0\", port=5000)
'"
fi

# Create model file
echo '{"model": "sample", "version": "1.0.0", "accuracy": 0.95}' > model.json

# Create deploy script
cat > deploy-model.sh << 'EOF'
#!/bin/bash
VERSION=${1:-1.0.0}
echo "Deploying model version $VERSION"
docker stop ml-service
docker rm ml-service
docker run -d --name ml-service -p 5000:5000 -e MODEL_VERSION=$VERSION python:3.9-slim sh -c "pip install flask && python -c '
from flask import Flask, jsonify, request
import os
app = Flask(__name__)
MODEL_VERSION = os.getenv(\"MODEL_VERSION\", \"1.0.0\")
@app.route(\"/health\")
def health():
    return jsonify({\"status\": \"healthy\", \"version\": MODEL_VERSION})
@app.route(\"/predict\", methods=[\"POST\"])
def predict():
    return jsonify({\"prediction\": \"class_a\", \"confidence\": 0.95, \"version\": MODEL_VERSION})
if __name__ == \"__main__\":
    app.run(host=\"0.0.0.0\", port=5000)'"
sleep 5
curl -s http://localhost:5000/health
EOF
chmod +x deploy-model.sh

# Create monitor script
cat > monitor.sh << 'EOF'
#!/bin/bash
while true; do
  if curl -f -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "$(date): Service healthy"
  else
    echo "$(date): Service unhealthy! Restarting..."
    docker restart ml-service
  fi
  sleep 10
done
EOF
chmod +x monitor.sh

# Create workflow file
mkdir -p .github/workflows
cat > .github/workflows/ml-pipeline.yml << 'EOF'
name: ML Pipeline
on:
  push:
    paths:
      - 'models/**'
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy Model
        run: echo "Deploying model..."
EOF

# Wait for services to start
echo "Waiting for services to start..."
sleep 20

# Configure MinIO
if command -v mc &> /dev/null; then
    mc alias set minio http://localhost:9000 minioadmin minioadmin
    mc mb minio/ml-models --ignore-existing
    mc cp model.json minio/ml-models/
else
    echo "MinIO client not found. Installing..."
    wget https://dl.min.io/client/mc/release/linux-amd64/mc
    chmod +x mc
    sudo mv mc /usr/local/bin/
    mc alias set minio http://localhost:9000 minioadmin minioadmin
    mc mb minio/ml-models --ignore-existing
    mc cp model.json minio/ml-models/
fi

echo ""
echo "Lab initialization complete!"
echo "MinIO Console: http://localhost:9001 (user: minioadmin, pass: minioadmin)"
echo "ML Service: http://localhost:5000"
echo ""
echo "Test with: curl http://localhost:5000/health"
