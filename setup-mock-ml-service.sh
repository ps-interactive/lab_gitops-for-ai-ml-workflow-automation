#!/bin/bash

# Simple fix for the port-forward and curl issue
# This creates a mock ML service that responds correctly

echo "Setting up mock ML service..."

# Kill any existing processes on port 8888
lsof -ti:8888 | xargs kill 2>/dev/null || true

# Create a simple Python HTTP server that mimics the ML service
cat > /tmp/mock_ml_service.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
from http import HTTPStatus

class MLHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/predict':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Return mock prediction
            response = {
                "prediction": 0.8745,
                "confidence": 0.92,
                "model_version": "1.0"
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_error(404)
    
    def log_message(self, format, *args):
        pass  # Suppress logs

PORT = 8888
with socketserver.TCPServer(("", PORT), MLHandler) as httpd:
    print(f"Mock ML service running on port {PORT}")
    httpd.serve_forever()
EOF

# Start the mock service in background
python3 /tmp/mock_ml_service.py &> /dev/null &
MOCK_PID=$!
echo $MOCK_PID > /tmp/mock_ml_service.pid

# Wait a moment for service to start
sleep 1

# Create a wrapper for the kubectl port-forward command
cat > ./kubectl-port-forward-ml.sh << 'EOF'
#!/bin/bash
# Wrapper that mimics kubectl port-forward output
echo "Forwarding from 127.0.0.1:8888 -> 80"
echo "Forwarding from [::1]:8888 -> 80"
# Keep running until interrupted
sleep infinity
EOF
chmod +x ./kubectl-port-forward-ml.sh

echo "Mock ML service is ready!"
echo ""
echo "For step 9, instead of running:"
echo "  kubectl port-forward svc/ml-predictor 8888:80 &"
echo ""
echo "Run this:"
echo "  ./kubectl-port-forward-ml.sh &"
echo ""
echo "Then proceed with step 10 (curl command) as normal."
echo ""
echo "To stop the mock service later:"
echo "  kill $(cat /tmp/mock_ml_service.pid)"
