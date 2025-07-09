#!/usr/bin/env python3
import os
import json
import time
from flask import Flask, jsonify, request
from minio import Minio
from datetime import datetime

app = Flask(__name__)

# MinIO configuration
minio_client = Minio(
    os.getenv('MINIO_ENDPOINT', 'localhost:9000'),
    access_key=os.getenv('MINIO_ACCESS_KEY', 'minioadmin'),
    secret_key=os.getenv('MINIO_SECRET_KEY', 'minioadmin'),
    secure=False
)

# Metrics for monitoring
metrics = {
    'requests_total': 0,
    'errors_total': 0,
    'model_version': os.getenv('MODEL_VERSION', '1.0.0'),
    'last_prediction_time': None
}

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_version': metrics['model_version']
    })

@app.route('/metrics')
def get_metrics():
    """Prometheus-compatible metrics endpoint"""
    output = []
    output.append(f'# HELP ml_service_requests_total Total requests')
    output.append(f'# TYPE ml_service_requests_total counter')
    output.append(f'ml_service_requests_total {metrics["requests_total"]}')
    output.append(f'# HELP ml_service_errors_total Total errors')
    output.append(f'# TYPE ml_service_errors_total counter') 
    output.append(f'ml_service_errors_total {metrics["errors_total"]}')
    return '\n'.join(output), 200, {'Content-Type': 'text/plain'}

@app.route('/model')
def get_model():
    """Get current model information"""
    metrics['requests_total'] += 1
    try:
        # Try to load model from MinIO
        response = minio_client.get_object('ml-models', f'model-v{metrics["model_version"]}.json')
        model_data = json.loads(response.read())
        response.close()
        response.release_conn()
        return jsonify(model_data)
    except:
        # Fallback to local file
        try:
            with open('/models/model.json', 'r') as f:
                return jsonify(json.load(f))
        except:
            metrics['errors_total'] += 1
            return jsonify({'error': 'Model not found'}), 404

@app.route('/predict', methods=['POST'])
def predict():
    """Simulate model prediction"""
    metrics['requests_total'] += 1
    try:
        data = request.get_json()
        # Simulate prediction
        prediction = {
            'prediction': 'class_a',
            'confidence': 0.95,
            'model_version': metrics['model_version'],
            'timestamp': datetime.now().isoformat()
        }
        metrics['last_prediction_time'] = time.time()
        return jsonify(prediction)
    except Exception as e:
        metrics['errors_total'] += 1
        return jsonify({'error': str(e)}), 400

@app.route('/rollback', methods=['POST'])
def rollback():
    """Simulate model rollback"""
    old_version = metrics['model_version']
    metrics['model_version'] = request.json.get('version', '1.0.0')
    return jsonify({
        'message': 'Rollback completed',
        'old_version': old_version,
        'new_version': metrics['model_version']
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
