#!/bin/bash

# MinIO backup script for GitOps ML Lab

echo "Setting up MinIO backup..."

# Check if MinIO client is configured
if ! mc alias list myminio > /dev/null 2>&1; then
    echo "Configuring MinIO client..."
    mc alias set myminio http://localhost:9000 minioadmin minioadmin
fi

# Create backup bucket if it doesn't exist
if ! mc ls myminio/ml-models-backup > /dev/null 2>&1; then
    echo "Creating backup bucket..."
    mc mb myminio/ml-models-backup
fi

# Perform backup
echo "Backing up ml-models to ml-models-backup..."
mc mirror myminio/ml-models myminio/ml-models-backup

# List backup contents
echo "Backup contents:"
mc ls myminio/ml-models-backup/

echo "Backup completed successfully!"
