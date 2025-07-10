#!/usr/bin/env python3
import pickle
import numpy as np
from sklearn.linear_model import LogisticRegression
import subprocess
import argparse

def create_dummy_model(version="v1"):
    # Create a simple model
    X = np.array([[1, 2], [2, 3], [3, 4], [4, 5]])
    y = np.array([0, 0, 1, 1])
    
    model = LogisticRegression()
    model.fit(X, y)
    
    # Save model
    model_name = f"test-model-{version}.pkl"
    with open(f"/tmp/{model_name}", 'wb') as f:
        pickle.dump(model, f)
    
    # Upload to MinIO
    cmd = f"mc cp /tmp/{model_name} myminio/ml-models/"
    subprocess.run(cmd, shell=True, check=True)
    
    print(f"Model {model_name} created and uploaded successfully!")
    return model_name

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', default='v1', help='Model version')
    args = parser.parse_args()
    
    create_dummy_model(args.version)
