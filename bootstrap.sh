#!/bin/bash
# Bootstrap script for GitOps ML Lab when cloud-init fails

echo "====================================="
echo "GitOps ML Lab Bootstrap Script"
echo "====================================="
echo "This script will install all required components"
echo ""

# Update the system
echo "Updating system packages..."
sudo yum update -y

# Install git
echo "Installing git..."
sudo yum install -y git

# Install Docker
echo "Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker cloud_user
echo "Docker installed. You may need to logout/login for group changes to take effect."

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install k3s
echo "Installing k3s (Kubernetes)..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

# Wait for k3s to be ready
echo "Waiting for k3s to start..."
sleep 10

# Setup kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Wait for k3s to be fully ready
echo "Waiting for k3s to be ready..."
for i in {1..30}; do
    if kubectl get nodes >/dev/null 2>&1; then
        echo "k3s is ready!"
        break
    fi
    echo -n "."
    sleep 2
done

# Install Python packages
echo "Installing Python packages..."
sudo yum install -y python3 python3-pip
pip3 install --user pyyaml requests boto3 scikit-learn

# Install MinIO client
echo "Installing MinIO client..."
sudo curl -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
sudo chmod +x /usr/local/bin/mc

# Setup bash completion
echo "Setting up bash completion..."
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc

# Clone the repository if not already present
if [ ! -d ~/lab-files ]; then
    echo "Cloning lab repository..."
    cd ~
    git clone https://github.com/ps-interactive/lab_gitops-for-ai-ml-workflow-automation.git lab-files
    chmod +x ~/lab-files/scripts/*.py
else
    echo "Lab files already exist"
fi

# Create setup.sh if not exists
if [ ! -f ~/setup.sh ]; then
    echo "Creating setup.sh..."
    cat > ~/setup.sh << 'EOF'
#!/bin/bash
echo "Setting up GitOps ML Lab environment..."
export KUBECONFIG=~/.kube/config

# Check Kubernetes
echo "Checking Kubernetes status..."
kubectl get nodes

if [ $? -eq 0 ]; then
    echo "Kubernetes is ready!"
else
    echo "Kubernetes is not ready yet. Waiting..."
    sleep 10
    kubectl get nodes
fi

# Start infrastructure services
echo "Starting infrastructure services..."
cd ~/lab-files

if [ -f infrastructure/docker-compose.yml ]; then
    docker-compose -f infrastructure/docker-compose.yml up -d
    echo "Services starting..."
    echo "Waiting for services to be ready..."
    
    # Wait for MinIO
    echo -n "Waiting for MinIO..."
    for i in {1..30}; do
        if curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1; then
            echo " Ready!"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Wait for Weaviate
    echo -n "Waiting for Weaviate..."
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
    echo "MinIO running on port 9000"
    echo "Weaviate running on port 8080"
else
    echo "Error: docker-compose.yml not found"
    exit 1
fi
EOF
    chmod +x ~/setup.sh
fi

echo ""
echo "====================================="
echo "Bootstrap complete!"
echo "====================================="
echo ""
echo "Next steps:"
echo "1. Logout and login again (or run 'newgrp docker')"
echo "2. Run './setup.sh' to start the lab services"
echo ""
echo "Note: It may take a minute for k3s to be fully ready."
