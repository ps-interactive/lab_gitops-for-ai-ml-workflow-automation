#!/usr/bin/env python3
import pickle
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import mlflow
import os
from datetime import datetime

def train_model():
    # Load data
    iris = load_iris()
    X = pd.DataFrame(iris.data, columns=iris.feature_names)
    y = iris.target
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Train model
    with mlflow.start_run():
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        
        # Make predictions
        predictions = model.predict(X_test)
        accuracy = accuracy_score(y_test, predictions)
        
        # Log metrics
        mlflow.log_metric("accuracy", accuracy)
        mlflow.log_param("n_estimators", 100)
        
        # Save model
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        model_path = f"models/model_v{timestamp}.pkl"
        os.makedirs("models", exist_ok=True)
        
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)
        
        print(f"Model trained with accuracy: {accuracy:.4f}")
        print(f"Model saved to: {model_path}")
        
        return model_path, accuracy

if __name__ == "__main__":
    train_model()
