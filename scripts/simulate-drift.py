#!/usr/bin/env python3
import subprocess
import argparse
import json

def deploy_model(model_name, replicas=1, canary=False):
    deployment_name = "model-server-canary" if canary else "model-server"
    
    # Update deployment with new model
    patch = {
        "spec": {
            "replicas": replicas,
            "template": {
                "spec": {
                    "containers": [{
                        "name": "model-server",
                        "env": [
                            {"name": "MODEL_NAME", "value": model_name},
                            {"name": "MODEL_PATH", "value": f"/models/{model_name}"}
                        ]
                    }]
                }
            }
        }
    }
    
    patch_json = json.dumps(patch)
    
    cmd = [
        "kubectl", "patch", "deployment", deployment_name,
        "-n", "ml-models",
        "--type", "merge",
        "-p", patch_json
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"Model {model_name} deployed successfully!")
        print(f"Deployment: {deployment_name}")
        print(f"Replicas: {replicas}")
    else:
        print(f"Error deploying model: {result.stderr}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True, help='Model name to deploy')
    parser.add_argument('--replicas', type=int, default=1, help='Number of replicas')
    parser.add_argument('--canary', action='store_true', help='Deploy as canary')
    args = parser.parse_args()
    
    deploy_model(args.model, args.replicas, args.canary)
