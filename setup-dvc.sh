#!/bin/bash

echo "Setting up DVC (Data Version Control)..."

# Install DVC
pip3 install --user dvc

# Add to PATH
export PATH=$PATH:$HOME/.local/bin

# Initialize DVC in the current directory
if [ ! -d ".dvc" ]; then
    dvc init --no-scm
    echo "DVC initialized"
fi

# Configure DVC storage
dvc remote add -d minio s3://ml-models
dvc remote modify minio endpointurl http://localhost:9000
dvc remote modify minio access_key_id minioadmin
dvc remote modify minio secret_access_key minioadmin

# Create .dvc directory structure
mkdir -p .dvc/cache
mkdir -p .dvc/tmp

echo "DVC setup complete!"
