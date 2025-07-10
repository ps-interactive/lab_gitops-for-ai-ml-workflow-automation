#!/bin/bash
echo "Setting up GitOps ML Lab environment..."
export KUBECONFIG=/home/cloud_user/.kube/config

# Check Kubernetes
echo "Checking Kubernetes status..."
kubectl get nodes

if [ $? -eq 0 ]; then
    echo "Kubernetes is ready!"
else
    echo "Kubernetes is not ready yet. Please wait a moment and try again."
    exit 1
fi

# Start infrastructure services
echo "Starting infrastructure services..."
cd /home/cloud_user/lab-files

# Check if docker-compose file exists
if [ ! -f infrastructure/docker-compose.yml ]; then
    echo "Error: docker-compose.yml not found. Please ensure you're in the lab-files directory."
    exit 1
fi

# Start services
docker-compose -f infrastructure/docker-compose.yml up -d

echo "Infrastructure services starting..."
echo "Waiting for services to be ready..."

# Wait for MinIO
echo -n "Waiting for MinIO to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        echo " Ready!"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for Weaviate
echo -n "Waiting for Weaviate to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8080/v1/.well-known/ready > /dev/null 2>&1; then
        echo " Ready!"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "Setup complete!"
echo "MinIO is running on port 9000 (console on 9001)"
echo "Weaviate is running on port 8080"
echo ""
echo "You can now proceed with the lab objectives."
