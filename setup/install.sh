#!/bin/bash -xe

# Update system
yum update -y
yum install -y git docker python3 python3-pip wget curl unzip
amazon-linux-extras install -y docker

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker cloud_user

# Create directories
mkdir -p /usr/local/bin/lab-scripts
mkdir -p /home/cloud_user/gitops-ml-lab/{src,scripts,manifests,models}

# Create kubectl mock
cat > /usr/local/bin/kubectl << 'EOF'
#!/bin/bash
case "$1" in
  get)
    case "$2" in
      nodes)
        echo "NAME       STATUS   ROLES           AGE   VERSION"
        echo "minikube   Ready    control-plane   5m    v1.28.3"
        ;;
      ksvc)
        if [[ "$3" == "ml-model-service" && "$4" == "-o" ]]; then
          echo "ml-model-service-v1"
        else
          echo "NAME                URL                                              LATESTCREATED           LATESTREADY             READY"
          echo "ml-model-service    http://ml-model-service.default.example.com     ml-model-service-v2     ml-model-service-v2     True"
        fi
        ;;
      pods)
        if [[ "$3" == "-n" && "$4" == "knative-serving" ]]; then
          echo "NAME                                     READY   STATUS    RESTARTS   AGE"
          echo "activator-7d9d6b9849-xlnvp               1/1     Running   0          5m"
          echo "autoscaler-6f7d6f9849-kqnvp              1/1     Running   0          5m"
          echo "controller-7d9d6b9849-plmvp              1/1     Running   0          5m"
          echo "domain-mapping-6f7d6f9849-wlnvp          1/1     Running   0          5m"
          echo "domainmapping-webhook-7d9d6b9849-qlnvp   1/1     Running   0          5m"
          echo "net-kourier-controller-6f7d6f9849-zlnvp  1/1     Running   0          5m"
          echo "webhook-7d9d6b9849-mlnvp                 1/1     Running   0          5m"
        elif [[ "$3" == "-l" && "$4" == "app=model-monitor" ]]; then
          echo "NAME                           READY   STATUS    RESTARTS   AGE"
          echo "model-monitor-5d8f9b6c4-j7kl9   1/1     Running   0          2m"
        fi
        ;;
      revisions)
        echo "NAME                      CONFIG NAME          K8S SERVICE NAME          GENERATION   READY   REASON   ACTUAL REPLICAS   DESIRED REPLICAS"
        echo "ml-model-service-v1       ml-model-service     ml-model-service-v1       1            True             1                 1"
        echo "ml-model-service-v2       ml-model-service     ml-model-service-v2       2            True             1                 1"
        ;;
    esac
    ;;
  apply)
    if [[ "$3" == *"ml-model-service.yaml" ]]; then
      echo "service.serving.knative.dev/ml-model-service created"
    elif [[ "$3" == *"monitoring-config.yaml" ]]; then
      echo "configmap/ml-monitoring-config created"
      echo "service/model-monitor created"
      echo "deployment.apps/model-monitor created"
    elif [[ "$3" == *"drift-alert-rule.yaml" ]]; then
      echo "configmap/drift-alert-rules created"
    fi
    ;;
  describe)
    if [[ "$2" == "configmap" && "$3" == "ml-monitoring-config" ]]; then
      echo "Name:         ml-monitoring-config"
      echo "Namespace:    default"
      echo "Labels:       <none>"
      echo "Annotations:  <none>"
      echo ""
      echo "Data"
      echo "===="
      echo "drift-threshold:"
      echo "----"
      echo "0.1"
      echo "accuracy-threshold:"
      echo "----"
      echo "0.85"
      echo "check-interval:"
      echo "----"
      echo "300"
    fi
    ;;
  patch)
    if [[ "$2" == "ksvc" && "$3" == "ml-model-service" ]]; then
      echo "service.serving.knative.dev/ml-model-service patched"
    fi
    ;;
esac
EOF
chmod +x /usr/local/bin/kubectl

# Create docker-compose mock
cat > /usr/local/bin/docker-compose << 'EOF'
#!/bin/bash
case "$1" in
  up)
    echo "Creating network gitops-ml-lab_default"
    echo "Creating volume gitops-ml-lab_minio_data"
    echo "Creating volume gitops-ml-lab_mlflow_data"
    echo "Creating gitops-ml-lab_minio_1 ... done"
    echo "Creating gitops-ml-lab_weaviate_1 ... done"
    echo "Creating gitops-ml-lab_mlflow_1 ... done"
    ;;
  ps)
    echo "        Name                      Command               State                    Ports"
    echo "------------------------------------------------------------------------------------------------"
    echo "gitops-ml-lab_minio_1      /usr/bin/docker-entrypoint ...   Up      0.0.0.0:9000->9000/tcp, 0.0.0.0:9001->9001/tcp"
    echo "gitops-ml-lab_mlflow_1     bash -c pip install mlflow ...   Up      0.0.0.0:5000->5000/tcp"
    echo "gitops-ml-lab_weaviate_1   /bin/weaviate --host 0.0. ...   Up      0.0.0.0:8080->8080/tcp"
    ;;
esac
EOF
chmod +x /usr/local/bin/docker-compose

# Create mc (MinIO client) alias
echo 'alias mc="/usr/local/bin/lab-scripts/mc-mock.sh"' >> /home/cloud_user/.bashrc

# Create mc mock script
cat > /usr/local/bin/lab-scripts/mc-mock.sh << 'EOF'
#!/bin/bash
case "$1" in
  config)
    echo "Added \`$4\` successfully."
    ;;
  mb)
    echo "Bucket \`${2#*/}\` created successfully"
    ;;
  cp)
    echo "\`$2\` -> \`$3\`"
    echo "Total: 0 B, Transferred: 1.2 MiB, Speed: 5.0 MiB/s"
    ;;
  ls)
    echo "[2025-01-15 10:30:45 UTC]  1.2MiB STANDARD model_v1.pkl"
    echo "[2025-01-15 11:45:22 UTC]  1.3MiB STANDARD model_v2.pkl"
    ;;
esac
EOF
chmod +x /usr/local/bin/lab-scripts/mc-mock.sh

# Create other aliases
echo 'alias weaviate-client="/usr/local/bin/lab-scripts/weaviate-mock.sh"' >> /home/cloud_user/.bashrc
echo 'alias mlflow="/usr/local/bin/lab-scripts/mlflow-mock.sh"' >> /home/cloud_user/.bashrc

# Create weaviate mock
cat > /usr/local/bin/lab-scripts/weaviate-mock.sh << 'EOF'
#!/bin/bash
if [[ "$1" == "schema" ]]; then
  echo '{"classes":[{"class":"MLModel","properties":[{"name":"name"},{"name":"version"},{"name":"accuracy"}]}]}'
elif [[ "$1" == "data" ]]; then
  echo '{"objects":[{"id":"uuid-1","properties":{"name":"iris-classifier","version":"v1","accuracy":0.95}}]}'
fi
EOF
chmod +x /usr/local/bin/lab-scripts/weaviate-mock.sh

# Create mlflow mock
cat > /usr/local/bin/lab-scripts/mlflow-mock.sh << 'EOF'
#!/bin/bash
if [[ "$1" == "runs" && "$2" == "list" ]]; then
  echo "Run ID                            Name    Status     Start Time"
  echo "--------------------------------  ------  ---------  -------------------"
  echo "abc123def456ghi789jkl012mno345    Run-1   FINISHED   2025-01-15 10:30:00"
  echo "xyz789uvw456rst123opq789lmn456    Run-2   FINISHED   2025-01-15 11:45:00"
elif [[ "$1" == "models" && "$2" == "list" ]]; then
  echo "Name              Latest Version"
  echo "----------------  --------------"
  echo "iris-classifier   2"
fi
EOF
chmod +x /usr/local/bin/lab-scripts/mlflow-mock.sh

# Create setup.sh script
cat > /home/cloud_user/setup.sh << 'EOF'
#!/bin/bash
echo 'Starting minikube...'
echo 'minikube v1.32.0 on Amazon 2'
echo 'Using the docker driver based on user configuration'
echo 'Starting control plane node minikube in cluster minikube'
echo 'Pulling base image ...'
echo 'Creating docker container (CPUs=2, Memory=4096MB) ...'
echo 'Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...'
echo '    Generating certificates and keys ...'
echo '    Booting up control plane ...'
echo '    Configuring RBAC rules ...'
echo 'Configuring bridge CNI (Container Networking Interface) ...'
echo 'Verifying Kubernetes components...'
echo '    Using image gcr.io/k8s-minikube/storage-provisioner:v5'
echo 'Enabled addons: storage-provisioner, default-storageclass'
echo 'Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default'
echo ''
echo 'Enabling required addons...'
echo 'ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.'
echo 'You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS'
echo '    Using image registry.k8s.io/ingress-nginx/controller:v1.9.4'
echo '    Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20231011-8b53cabe0'
echo 'Verifying ingress addon...'
echo 'The ingress addon is enabled'
echo 'The metrics-server addon is enabled'
echo ''
echo 'Installing Knative Serving...'
sleep 1
echo 'customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev created'
echo 'customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev created'
echo 'customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev created'
echo 'namespace/knative-serving created'
echo 'deployment.apps/activator created'
echo 'deployment.apps/autoscaler created'
echo 'deployment.apps/controller created'
echo 'deployment.apps/domain-mapping created'
echo 'deployment.apps/domainmapping-webhook created'
echo 'deployment.apps/webhook created'
echo 'service/activator-service created'
echo 'service/autoscaler created'
echo 'service/controller created'
echo 'service/domainmapping-webhook created'
echo 'service/webhook created'
echo 'configmap/config-network patched'
echo ''
echo 'Waiting for Knative to be ready...'
sleep 2
echo 'pod/activator-7d9d6b9849-xlnvp condition met'
echo 'pod/autoscaler-6f7d6f9849-kqnvp condition met'
echo 'pod/controller-7d9d6b9849-plmvp condition met'
echo 'pod/domain-mapping-6f7d6f9849-wlnvp condition met'
echo 'pod/domainmapping-webhook-7d9d6b9849-qlnvp condition met'
echo 'pod/webhook-7d9d6b9849-mlnvp condition met'
echo 'Setup complete!'
EOF
chmod +x /home/cloud_user/setup.sh

# Create Python scripts
cat > /home/cloud_user/gitops-ml-lab/src/train_model.py << 'EOF'
#!/usr/bin/env python3
import os
from datetime import datetime

def train_model():
    os.makedirs("models", exist_ok=True)
    print("Loading data...")
    print("Training RandomForestClassifier with 100 estimators...")
    print("Evaluating model performance...")
    accuracy = 0.9667
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    model_path = f"models/model_v{timestamp}.pkl"
    with open(model_path, 'wb') as f:
        f.write(b"MOCK_MODEL_DATA_IRIS_CLASSIFIER_v2")
    print(f"Model trained with accuracy: {accuracy:.4f}")
    print(f"Model saved to: {model_path}")
    return model_path, accuracy

if __name__ == "__main__":
    train_model()
EOF

cat > /home/cloud_user/gitops-ml-lab/src/test_model.py << 'EOF'
#!/usr/bin/env python3
import sys
import os

def test_model():
    models_dir = "models"
    if not os.path.exists(models_dir):
        print("No models directory found")
        return False
    model_files = [f for f in os.listdir(models_dir) if f.endswith('.pkl')]
    if not model_files:
        print("No model files found")
        return False
    latest_model = sorted(model_files)[-1]
    print(f"Testing model: {latest_model}")
    print("Running inference on test samples...")
    print("Sample predictions: [0 0 1 1 2]")
    print("Model test passed!")
    return True

if __name__ == "__main__":
    success = test_model()
    sys.exit(0 if success else 1)
EOF

# Create manifest files
cat > /home/cloud_user/gitops-ml-lab/manifests/ml-model-service.yaml << 'EOF'
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: ml-model-service
  namespace: default
spec:
  template:
    spec:
      containers:
      - image: python:3.9-slim
        ports:
        - containerPort: 8000
EOF

cat > /home/cloud_user/gitops-ml-lab/manifests/monitoring-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ml-monitoring-config
  namespace: default
data:
  drift-threshold: "0.1"
  accuracy-threshold: "0.85"
  check-interval: "300"
---
apiVersion: v1
kind: Service
metadata:
  name: model-monitor
  namespace: default
spec:
  selector:
    app: model-monitor
  ports:
  - port: 8000
    targetPort: 8000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: model-monitor
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: model-monitor
  template:
    metadata:
      labels:
        app: model-monitor
    spec:
      containers:
      - name: monitor
        image: python:3.9-slim
        ports:
        - containerPort: 8000
EOF

# Create docker-compose.yml
cat > /home/cloud_user/gitops-ml-lab/docker-compose.yml << 'EOF'
version: '3.8'
services:
  minio:
    image: minio/minio:latest
    ports:
      - "9000:9000"
      - "9001:9001"
  weaviate:
    image: semitechnologies/weaviate:latest
    ports:
      - "8080:8080"
  mlflow:
    image: python:3.9-slim
    ports:
      - "5000:5000"
volumes:
  minio_data:
  mlflow_data:
EOF

# Create mock setup scripts
cat > /home/cloud_user/gitops-ml-lab/scripts/setup-mock.sh << 'EOF'
#!/bin/bash
echo "Setting up mock environment..."
echo 'alias mc="/usr/local/bin/lab-scripts/mc-mock.sh"' >> ~/.bashrc
echo 'alias weaviate-client="/usr/local/bin/lab-scripts/weaviate-mock.sh"' >> ~/.bashrc
echo 'alias mlflow="/usr/local/bin/lab-scripts/mlflow-mock.sh"' >> ~/.bashrc
echo "Mock environment setup complete!"
echo "Please run: source ~/.bashrc"
EOF

cat > /home/cloud_user/gitops-ml-lab/scripts/cleanup-mock.sh << 'EOF'
#!/bin/bash
echo "Cleaning up mock environment..."
sed -i '/alias mc=/d' ~/.bashrc
sed -i '/alias weaviate-client=/d' ~/.bashrc
sed -i '/alias mlflow=/d' ~/.bashrc
echo "Mock environment cleanup complete!"
EOF

chmod +x /home/cloud_user/gitops-ml-lab/scripts/*.sh

# Setup kubectl completion
echo 'source <(kubectl completion bash)' >> /home/cloud_user/.bashrc
echo 'alias k=kubectl' >> /home/cloud_user/.bashrc
echo 'complete -F __start_kubectl k' >> /home/cloud_user/.bashrc

# Create .gitconfig
cat > /home/cloud_user/.gitconfig << 'EOF'
[user]
  name = Cloud User
  email = cloud_user@carvedrock.com
EOF

# Create .github/workflows directory
mkdir -p /home/cloud_user/gitops-ml-lab/.github/workflows
cat > /home/cloud_user/gitops-ml-lab/.github/workflows/ml-pipeline.yml << 'EOF'
name: ML Pipeline
on:
  push:
    paths:
      - 'models/**'
      - 'src/**'
  workflow_dispatch:
jobs:
  train-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    - name: Train model
      run: python src/train_model.py
    - name: Run tests
      run: python src/test_model.py
    - name: Upload model to MinIO
      run: echo "Model uploaded to MinIO"
    - name: Deploy to Kubernetes
      run: echo "Model deployed to Kubernetes"
EOF

# Fix ownership
chown -R cloud_user:cloud_user /home/cloud_user

echo "Installation complete!"
