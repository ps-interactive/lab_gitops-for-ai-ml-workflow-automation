#!/usr/bin/env python3
import requests
import json

WEAVIATE_URL = "http://localhost:8080"

def list_models():
    query = {
        "query": """
        {
            Get {
                MLModel {
                    modelName
                    version
                    accuracy
                    deploymentStatus
                    createdAt
                    s3Path
                }
            }
        }
        """
    }
    
    response = requests.post(
        f"{WEAVIATE_URL}/v1/graphql",
        json=query,
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        data = response.json()
        models = data.get('data', {}).get('Get', {}).get('MLModel', [])
        
        print("Registered Models:")
        print("-" * 80)
        for model in models:
            print(f"Name: {model['modelName']}")
            print(f"Version: {model['version']}")
            print(f"Accuracy: {model['accuracy']}")
            print(f"Status: {model['deploymentStatus']}")
            print(f"Created: {model['createdAt']}")
            print(f"Path: {model['s3Path']}")
            print("-" * 80)
    else:
        print(f"Error querying models: {response.text}")

if __name__ == "__main__":
    list_models()
