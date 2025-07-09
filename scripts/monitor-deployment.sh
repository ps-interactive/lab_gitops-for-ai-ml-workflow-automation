#!/bin/bash

# Simple monitoring script for ML deployments
echo "Starting ML deployment monitoring..."

# Check Knative service status
check_service_status() {
    kubectl get ksvc ml-model-service -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'
}

# Monitor deployment health
monitor_deployment() {
    local retries=0
    local max_retries=5
    
    while [ $retries -lt $max_retries ]; do
        status=$(check_service_status)
        
        if [ "$status" == "True" ]; then
            echo "✓ Deployment is healthy"
            return 0
        else
            echo "✗ Deployment unhealthy, checking again in 10 seconds..."
            sleep 10
            retries=$((retries + 1))
        fi
    done
    
    echo "✗ Deployment failed health checks"
    return 1
}

# Main monitoring loop
monitor_deployment

if [ $? -ne 0 ]; then
    echo "Triggering rollback..."
    kubectl rollout undo deployment/ml-model-service
fi
