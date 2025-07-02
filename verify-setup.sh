#!/bin/bash

echo "Verifying GitOps Lab Setup..."
echo "============================="

# Check if running as cloud_user
echo -n "Current user: "
whoami

# Check Docker
echo -n "Docker status: "
if docker --version >/dev/null 2>&1; then
    echo "OK - $(docker --version)"
else
    echo "ERROR - Docker not accessible"
fi

# Check docker-compose
echo -n "Docker Compose status: "
if docker-compose --version >/dev/null 2>&1; then
    echo "OK - $(docker-compose --version)"
else
    echo "ERROR - Docker Compose not found"
fi

# Check kubectl
echo -n "kubectl status: "
if kubectl version --client >/dev/null 2>&1; then
    echo "OK - $(kubectl version --client --short)"
else
    echo "ERROR - kubectl not found"
fi

# Check k3d
echo -n "k3d status: "
if k3d --version >/dev/null 2>&1; then
    echo "OK - $(k3d --version | head -1)"
else
    echo "ERROR - k3d not found"
fi

# Check MinIO client
echo -n "MinIO client status: "
if mc --version >/dev/null 2>&1; then
    echo "OK - installed"
else
    echo "ERROR - MinIO client not found"
fi

# Check for lab files
echo -n "Lab files: "
if [ -f ~/gitops-lab/docker-compose.yml ]; then
    echo "OK - found in ~/gitops-lab/"
else
    echo "ERROR - not found in ~/gitops-lab/"
fi

# List k3d clusters
echo ""
echo "Existing k3d clusters:"
k3d cluster list 2>/dev/null || echo "  No clusters found or k3d error"

echo ""
echo "Setup verification complete!"
