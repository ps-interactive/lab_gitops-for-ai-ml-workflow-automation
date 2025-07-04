cat > kubectl-port-forward-ml.sh << 'EOF'
#!/bin/bash
echo "Forwarding from 127.0.0.1:8888 -> 80"
echo "Forwarding from [::1]:8888 -> 80"

# Start a real service that responds on port 8888
python3 -c '
import http.server
import socketserver
import json

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/predict":
            response = {"prediction": 0.8745, "confidence": 0.92, "model_version": "1.0"}
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", 8888), Handler) as httpd:
    httpd.serve_forever()
' &
EOF

chmod +x kubectl-port-forward-ml.sh
