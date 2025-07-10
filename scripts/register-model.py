#!/usr/bin/env python3
import requests
import json
import argparse
from datetime import datetime

WEAVIATE_URL = "http://localhost:8080"

def register_model(model_name, accuracy):
    model_data = {
        "class": "MLModel",
        "properties": {
            "modelName": model_name,
            "version": model_name.split('-')[-1].replace('.pkl', ''),
            "accuracy": accuracy,
            "deploymentStatus": "registered",
            "createdAt": datetime.utcnow().isoformat() + "Z",
            "s3Path": f"s3://ml-models/{model_name}"
        }
    }
    
    response = requests.post(
        f"{WEAVIATE_URL}/v1/objects",
        json=model_data,
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        print(f"Model {model_name} registered successfully!")
        print(f"Object ID: {response.json()['id']}")
    else:
        print(f"Error registering model: {response.text}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True, help='Model name')
    parser.add_argument('--accuracy', type=float, required=True, help='Model accuracy')
    args = parser.parse_args()
    
    register_model(args.model, args.accuracy)
