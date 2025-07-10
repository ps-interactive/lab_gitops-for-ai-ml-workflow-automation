#!/usr/bin/env python3
import requests
import json

WEAVIATE_URL = "http://localhost:8080"

schema = {
    "class": "MLModel",
    "description": "Machine Learning Model Metadata",
    "properties": [
        {
            "name": "modelName",
            "dataType": ["text"],
            "description": "Name of the ML model"
        },
        {
            "name": "version",
            "dataType": ["text"],
            "description": "Version of the model"
        },
        {
            "name": "accuracy",
            "dataType": ["number"],
            "description": "Model accuracy score"
        },
        {
            "name": "deploymentStatus",
            "dataType": ["text"],
            "description": "Current deployment status"
        },
        {
            "name": "createdAt",
            "dataType": ["date"],
            "description": "Creation timestamp"
        },
        {
            "name": "s3Path",
            "dataType": ["text"],
            "description": "Path to model in object storage"
        }
    ]
}

def create_schema():
    try:
        response = requests.post(
            f"{WEAVIATE_URL}/v1/schema",
            json=schema,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            print("Schema created successfully!")
        else:
            print(f"Schema already exists or error: {response.text}")
    except Exception as e:
        print(f"Error creating schema: {e}")

if __name__ == "__main__":
    create_schema()
