#!/bin/bash

# This script removes mock commands
echo "Cleaning up mock environment..."

# Remove aliases
sed -i '/alias mc=/d' ~/.bashrc
sed -i '/alias weaviate-client=/d' ~/.bashrc
sed -i '/alias mlflow=/d' ~/.bashrc

# Restore real kubectl
if [ -f /usr/local/bin/kubectl.real ]; then
    sudo rm -f /usr/local/bin/kubectl
    sudo mv /usr/local/bin/kubectl.real /usr/local/bin/kubectl
fi

echo "Mock environment cleanup complete!"
