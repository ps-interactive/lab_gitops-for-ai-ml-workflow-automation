#!/usr/bin/env python3
import argparse
import requests
import json

WEAVIATE_URL = "http://localhost:8080"

def simulate_drift(model_name, degradation):
    # Query for the model
    query = {
        "query": f"""
        {{
            Get {{
                MLModel(where: {{
                    path: ["modelName"]
                    operator: Equal
                    valueText: "{model_name}"
                }}) {{
                    _additional {{
                        id
                    }}
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
            model = models[0]
            model_id = model['_additional']['id']
            current_accuracy = model['accuracy']
            new_accuracy = max(0, current_accuracy - degradation)
            
            # Update the model accuracy
            update_data = {
                "class": "MLModel",
                "properties": {
                    "accuracy": new_accuracy
                }
            }
            
            update_response = requests.patch(
                f"{WEAVIATE_URL}/v1/objects/{model_id}",
                json=update_data,
                headers={"Content-Type": "application/json"}
            )
            
            if update_response.status_code == 204:
                print(f"Simulated drift for {model_name}")
                print(f"Accuracy degraded from {current_accuracy:.2f} to {new_accuracy:.2f}")
            else:
                print(f"Error updating model: {update_response.text}")
        else:
            print(f"Model {model_name} not found")
    else:
        print(f"Error querying model: {response.text}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True, help='Model name')
    parser.add_argument('--degradation', type=float, required=True, help='Accuracy degradation')
    args = parser.parse_args()
    
    simulate_drift(args.model, args.degradation)
