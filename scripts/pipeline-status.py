#!/usr/bin/env python3
import subprocess
import requests
import json

def check_infrastructure():
    print("=== Infrastructure Status ===")
    
    # Check Docker containers
    cmd = ["docker-compose", "-f", "infrastructure/docker-compose.yml", "ps", "--format", "json"]
    result = subprocess.run(cmd, capture_output=True, text=True, cwd="/home/cloud_user/lab-files")
    
    if result.returncode == 0:
        print("✓ Docker Compose services running")
    else:
        print("✗ Docker Compose services issue")
    
    # Check MinIO
    try:
        response = requests.get("http://localhost:9000/minio/health/live")
        if response.status_code == 200:
            print("✓ MinIO is healthy")
        else:
            print("✗ MinIO health check failed")
    except:
        print("✗ MinIO is not reachable")
    
    # Check Weaviate
    try:
        response = requests.get("http://localhost:8080/v1/.well-known/ready")
        if response.status_code == 200:
            print("✓ Weaviate is ready")
        else:
            print("✗ Weaviate not ready")
    except:
        print("✗ Weaviate is not reachable")

def check_kubernetes():
    print("\n=== Kubernetes Status ===")
    
    # Check nodes
    cmd = ["kubectl", "get", "nodes", "-o", "json"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        nodes = json.loads(result.stdout)
        print(f"✓ Kubernetes cluster: {len(nodes['items'])} node(s)")
    else:
        print("✗ Kubernetes cluster issue")
    
    # Check deployments
    cmd = ["kubectl", "get", "deployments", "-n", "ml-models", "-o", "json"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        deployments = json.loads(result.stdout)
        for dep in deployments.get('items', []):
            name = dep['metadata']['name']
            ready = dep['status'].get('readyReplicas', 0)
            desired = dep['spec']['replicas']
            status = "✓" if ready == desired else "✗"
            print(f"{status} Deployment {name}: {ready}/{desired} replicas")
    else:
        print("✗ Cannot check deployments")

def check_models():
    print("\n=== Model Registry Status ===")
    
    # List models in MinIO
    cmd = ["mc", "ls", "myminio/ml-models/", "--json"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        models = 0
        for line in result.stdout.strip().split('\n'):
            if line:
                models += 1
        print(f"✓ MinIO: {models} model(s) stored")
    else:
        print("✗ Cannot access MinIO models")
    
    # Check Weaviate models
    try:
        query = {
            "query": """
            {
                Aggregate {
                    MLModel {
                        meta {
                            count
                        }
                    }
                }
            }
            """
        }
        response = requests.post(
            "http://localhost:8080/v1/graphql",
            json=query,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            data = response.json()
            count = data['data']['Aggregate']['MLModel'][0]['meta']['count']
            print(f"✓ Weaviate: {count} model(s) registered")
        else:
            print("✗ Cannot query Weaviate")
    except:
        print("✗ Weaviate query failed")

def main():
    print("GitOps ML Pipeline Status Report")
    print("=" * 40)
    
    check_infrastructure()
    check_kubernetes()
    check_models()
    
    print("\n" + "=" * 40)
    print("Pipeline status check complete!")

if __name__ == "__main__":
    main()
