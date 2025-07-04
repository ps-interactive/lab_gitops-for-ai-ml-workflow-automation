#!/usr/bin/env python3
import pickle
import pandas as pd
from sklearn.datasets import load_iris
import sys
import os

def test_model():
    # Find latest model
    models_dir = "models"
    if not os.path.exists(models_dir):
        print("No models directory found")
        return False
    
    model_files = [f for f in os.listdir(models_dir) if f.endswith('.pkl')]
    if not model_files:
        print("No model files found")
        return False
    
    latest_model = sorted(model_files)[-1]
    model_path = os.path.join(models_dir, latest_model)
    
    # Load model
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    
    # Test predictions
    iris = load_iris()
    X_test = pd.DataFrame(iris.data[:5], columns=iris.feature_names)
    predictions = model.predict(X_test)
    
    print(f"Testing model: {latest_model}")
    print(f"Sample predictions: {predictions}")
    
    # Basic validation
    if len(predictions) == 5 and all(p in [0, 1, 2] for p in predictions):
        print("Model test passed!")
        return True
    else:
        print("Model test failed!")
        return False

if __name__ == "__main__":
    success = test_model()
    sys.exit(0 if success else 1)
