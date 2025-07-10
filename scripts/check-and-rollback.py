#!/usr/bin/env python3
import subprocess
import requests
import json

WEAVIATE_URL = "http://localhost:8080"
ACCURACY_THRESHOLD = 0.8

def get_deployed_model():
    cmd = ["kubectl", "get", "deployment", "model-server", "-n", "ml-models", 
           "-o", "jsonpath={.spec.template.spec.containers[0].env[?(@.name=='MODEL_NAME')].value}"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip()

def check_model_accuracy(model_name):
    query = {
        "query": f"""
        {{
            Get {{
                MLModel(where: {{
                    path: ["modelName"]
                    operator: Equal
                    valueText: "{model_name}"
                }}) {{
                    accuracy
                }}
            }}
        }}
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
        if models:
            return models[0]['accuracy']
    return None

def rollback_deployment():
    cmd = ["kubectl", "rollout", "undo", "deployment/model-server", "-n", "ml-models"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print("Rollback initiated successfully!")
    else:
        print(f"Error during rollback: {result.stderr}")

def main():
    model_name = get_deployed_model()
    print(f"Currently deployed model: {model_name}")
    
    if model_name:
        accuracy = check_model_accuracy(model_name)
        if accuracy is not None:
            print(f"Model accuracy: {accuracy:.2f}")
            
            if accuracy < ACCURACY_THRESHOLD:
                print(f"Model accuracy below threshold ({ACCURACY_THRESHOLD})")
                print("Initiating rollback...")
                rollback_deployment()
            else:
                print("Model accuracy is acceptable")
        else:
            print("Could not retrieve model accuracy")
    else:
        print("Could not determine deployed model")

if __name__ == "__main__":
    main()
