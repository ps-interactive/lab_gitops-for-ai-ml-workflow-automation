#!/bin/bash

# This script sets up mock commands for the lab environment
echo "Setting up mock environment..."

# Create aliases for mock commands
echo 'alias mc="/usr/local/bin/lab-scripts/minio-mock.sh"' >> ~/.bashrc
echo 'alias weaviate-client="/usr/local/bin/lab-scripts/weaviate-mock.sh"' >> ~/.bashrc
echo 'alias mlflow="/usr/local/bin/lab-scripts/mlflow-mock.sh"' >> ~/.bashrc

# Backup real kubectl if exists
if [ -f /usr/local/bin/kubectl ]; then
    sudo mv /usr/local/bin/kubectl /usr/local/bin/kubectl.real
fi
sudo ln -sf /usr/local/bin/lab-scripts/kubectl-mock.sh /usr/local/bin/kubectl

echo "Mock environment setup complete!"
echo "Please run: source ~/.bashrc"
