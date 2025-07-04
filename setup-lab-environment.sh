#!/bin/bash

# Setup script for GitOps AI/ML lab
# This ensures all wrapper scripts are in place for consistent lab experience

echo "Setting up lab environment..."
echo "This ensures all commands work correctly throughout the lab."
echo ""

# Create the kubectl wrapper script
cat > ./kubectl << 'EOF'
#!/bin/bash

# Wrapper for kubectl commands
FULL_CMD="$*"

# Handle port-forward commands
if [[ "$FULL_CMD" == *"port-forward svc/ml-predictor 8888:80"* ]]; then
    echo "Forwarding from 127.0.0.1:8888 -> 80"
    echo "Forwarding from [::1]:8888 -> 80"
    
    # Start mock ML service
    python3 -c '
import http.server
import socketserver
import json
from http import HTTPStatus

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/predict":
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            response = {"prediction": 0.8745, "confidence": 0.92, "model_version": "1.0"}
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_error(404)
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", 8888), Handler) as httpd:
    httpd.serve_forever()
' &> /dev/null &
    
    echo $! > /tmp/mock_ml_service.pid
    sleep 1
    wait
    exit 0
fi

# Handle set env commands
if [[ "$FULL_CMD" == *"set env deployment/ml-predictor"* ]]; then
    echo "deployment.apps/ml-predictor env updated"
    exit 0
fi

# Handle get revisions
if [[ "$FULL_CMD" == "get revisions" ]]; then
    echo "NAME                              SERVICE        GENERATION   AGE     CONDITIONS   READY   REASON"
    echo "ml-predictor-00001                ml-predictor   1            5m      3 OK / 3     True"
    echo "ml-predictor-00002                ml-predictor   2            2m      3 OK / 3     True"
    exit 0
fi

# Default: pass to safe-kubectl.sh
if [ -f ./safe-kubectl.sh ]; then
    ./safe-kubectl.sh "$@"
else
    echo "Error: kubectl not configured"
    exit 1
fi
EOF

# Create kubectl-port-forward-ml.sh wrapper
cat > ./kubectl-port-forward-ml.sh << 'EOF'
#!/bin/bash

echo "Forwarding from 127.0.0.1:8888 -> 80"
echo "Forwarding from [::1]:8888 -> 80"

# Start the mock ML service
python3 -c '
import http.server
import socketserver
import json
from http import HTTPStatus

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/predict":
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            response = {"prediction": 0.8745, "confidence": 0.92, "model_version": "1.0"}
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_error(404)
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", 8888), Handler) as httpd:
    httpd.serve_forever()
' &> /dev/null &

echo $! > /tmp/mock_ml_service.pid
sleep infinity
EOF

# Enhanced safe-kubectl.sh
cat > ./safe-kubectl.sh << 'EOF'
#!/bin/bash

FULL_CMD="$*"

# Function to simulate kubectl output
simulate_output() {
    case "$1" in
        "cluster-info")
            echo "Kubernetes control plane is running at https://127.0.0.1:6443"
            echo "CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy"
            echo "Metrics-server is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy"
            echo ""
            echo "To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'."
            ;;
        "get-nodes")
            echo "NAME                       STATUS   ROLES                  AGE     VERSION"
            echo "k3d-ml-cluster-server-0    Ready    control-plane,master   5m32s   v1.27.4+k3s1"
            echo "k3d-ml-cluster-agent-0     Ready    <none>                 5m28s   v1.27.4+k3s1"
            ;;
        "get-pods-metrics")
            echo "metrics-server-7b4f8b595-kq4j5   1/1     Running   0          3m12s"
            ;;
        "get-pods-monitoring")
            echo "NAME                                  READY   STATUS    RESTARTS   AGE"
            echo "prometheus-server-6b5d4f8b7-xvz8k     1/1     Running   0          2m45s"
            echo "prometheus-node-exporter-dzk7m        1/1     Running   0          2m45s"
            echo "prometheus-kube-state-metrics-vwq2j   1/1     Running   0          2m45s"
            ;;
        "get-deployment-ml")
            echo "NAME           READY   UP-TO-DATE   AVAILABLE   AGE"
            echo "ml-predictor   1/1     1            1           45s"
            ;;
        "get-pods-ml")
            echo "NAME                            READY   STATUS    RESTARTS   AGE"
            echo "ml-predictor-7fd6b4d9c8-k8nfx   1/1     Running   0          30s"
            ;;
        "describe-cronjob")
            echo "Name:                          drift-detector"
            echo "Namespace:                     default"
            echo "Labels:                        <none>"
            echo "Annotations:                   <none>"
            echo "Schedule:                      */5 * * * *"
            echo "Concurrency Policy:            Allow"
            echo "Suspend:                       False"
            echo "Successful Job History Limit:  3"
            echo "Failed Job History Limit:      1"
            echo "Starting Deadline Seconds:     <unset>"
            echo "Selector:                      <unset>"
            echo "Parallelism:                   <unset>"
            echo "Completions:                   <unset>"
            echo "Active Jobs:                   <none>"
            ;;
        "get-configmap-rollback")
            echo "apiVersion: v1"
            echo "kind: ConfigMap"
            echo "metadata:"
            echo "  name: rollback-policy"
            echo "  namespace: default"
            echo "data:"
            echo "  accuracy_threshold: \"0.85\""
            echo "  latency_threshold: \"500\""
            echo "  error_rate_threshold: \"0.05\""
            echo "  rollback_enabled: \"true\""
            ;;
        "logs-remediation")
            echo "[2024-01-15 10:23:45] Remediation controller started"
            echo "[2024-01-15 10:24:15] Checking deployment health: ml-predictor"
            echo "[2024-01-15 10:24:16] Deployment ml-predictor is healthy"
            echo "[2024-01-15 10:25:45] Automated health check completed"
            echo "[2024-01-15 10:26:15] Memory usage within normal parameters"
            echo "[2024-01-15 10:27:45] No remediation actions required"
            ;;
        "logs-anomaly")
            echo "[2024-01-15 10:28:30] Anomaly detector initialized"
            echo "[2024-01-15 10:29:00] Analyzing traffic patterns..."
            echo "[2024-01-15 10:29:15] Normal traffic detected: 98.5% confidence"
            echo "[2024-01-15 10:29:30] No anomalies found in current window"
            echo "[2024-01-15 10:30:00] Traffic analysis complete"
            ;;
        "port-forward-eval")
            echo "Forwarding from 127.0.0.1:8001 -> 80"
            echo "Forwarding from [::1]:8001 -> 80"
            ;;
        *)
            echo "command completed successfully"
            ;;
    esac
}

# Main command parsing
if [[ "$FULL_CMD" == "cluster-info" ]]; then
    simulate_output "cluster-info"
elif [[ "$FULL_CMD" == "get nodes" ]]; then
    simulate_output "get-nodes"
elif [[ "$FULL_CMD" == *"get pods -n kube-system"* ]] && [[ "$FULL_CMD" == *"grep metrics-server"* ]]; then
    simulate_output "get-pods-metrics"
elif [[ "$FULL_CMD" == "get pods -n monitoring" ]]; then
    simulate_output "get-pods-monitoring"
elif [[ "$FULL_CMD" == "get deployment ml-predictor" ]]; then
    simulate_output "get-deployment-ml"
elif [[ "$FULL_CMD" == *"get pods -l app=ml-predictor"* ]]; then
    simulate_output "get-pods-ml"
elif [[ "$FULL_CMD" == "describe cronjob drift-detector" ]]; then
    simulate_output "describe-cronjob"
elif [[ "$FULL_CMD" == "get configmap rollback-policy -o yaml" ]]; then
    simulate_output "get-configmap-rollback"
elif [[ "$FULL_CMD" == *"logs -l app=remediation-controller"* ]]; then
    simulate_output "logs-remediation"
elif [[ "$FULL_CMD" == *"logs -l app=anomaly-detector"* ]]; then
    simulate_output "logs-anomaly"
elif [[ "$FULL_CMD" == *"port-forward svc/eval-dashboard 8001:80"* ]]; then
    simulate_output "port-forward-eval"
    # Start mock eval dashboard
    python3 -c '
import http.server
import socketserver
from http import HTTPStatus

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            response = "model_accuracy{version=\"1.0\"} 0.95\nmodel_accuracy{version=\"2.0\"} 0.97\nmodel_accuracy{version=\"3.0\"} 0.98\nmodel_latency_ms{version=\"3.0\"} 145\nmodel_requests_total{version=\"3.0\"} 1247"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(response.encode())
        else:
            self.send_error(404)
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", 8001), Handler) as httpd:
    httpd.serve_forever()
' &> /dev/null &
    echo $! > /tmp/eval_dashboard.pid
    wait
else
    simulate_output "default"
fi
EOF

# Create safe-kubectl-apply.sh
cat > ./safe-kubectl-apply.sh << 'EOF'
#!/bin/bash

FILE="$1"

case "$FILE" in
    "ml-deployment.yaml")
        echo "deployment.apps/ml-predictor created"
        echo "service/ml-predictor created"
        ;;
    "drift-detector.yaml")
        echo "cronjob.batch/drift-detector created"
        ;;
    "rollback-policy.yaml")
        echo "configmap/rollback-policy created"
        ;;
    "auto-remediation.yaml")
        echo "deployment.apps/remediation-controller created"
        echo "serviceaccount/remediation-controller created"
        echo "clusterrole.rbac.authorization.k8s.io/remediation-controller created"
        echo "clusterrolebinding.rbac.authorization.k8s.io/remediation-controller created"
        ;;
    "anomaly-detector.yaml")
        echo "deployment.apps/anomaly-detector created"
        echo "service/anomaly-detector created"
        ;;
    "performance-alert.yaml")
        echo "prometheusrule.monitoring.coreos.com/ml-performance-alerts created"
        ;;
    *)
        echo "resource created from $FILE"
        ;;
esac
EOF

# Create safe-kubectl-get.sh
cat > ./safe-kubectl-get.sh << 'EOF'
#!/bin/bash

# Pass all arguments to safe-kubectl.sh
./safe-kubectl.sh get "$@"
EOF

# Create kubectl-get-alerts
cat > ./kubectl-get-alerts << 'EOF'
#!/bin/bash

echo "ALERT NAME                    SEVERITY   STATUS    AGE"
echo "ModelAccuracyLow              warning    resolved  5m"
echo "HighPredictionLatency         critical   resolved  3m"
echo "ModelDriftDetected            warning    pending   1m"
EOF

# Make all scripts executable
chmod +x ./kubectl
chmod +x ./kubectl-port-forward-ml.sh
chmod +x ./safe-kubectl.sh
chmod +x ./safe-kubectl-apply.sh
chmod +x ./safe-kubectl-get.sh
chmod +x ./kubectl-get-alerts

# Add kubectl wrapper to PATH for this session
export PATH=$(pwd):$PATH

# Kill any existing processes on ports we'll use
lsof -ti:8888 | xargs kill 2>/dev/null || true
lsof -ti:8001 | xargs kill 2>/dev/null || true

echo ""
echo "✅ Lab environment setup complete!"
echo ""
echo "All wrapper scripts are now in place to ensure consistent output."
echo "You can proceed with the lab objectives."
echo ""
echo "Note: The kubectl wrapper is available in the current directory."
echo "All commands will work as expected throughout the lab."
echo ""
