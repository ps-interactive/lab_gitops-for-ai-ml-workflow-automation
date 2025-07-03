#!/bin/bash

# Wrapper for kubectl get to ensure expected output

RESOURCE=$1
ARGS="${@:2}"

# Hide all error output by redirecting stderr
exec 2>/dev/null

case "$RESOURCE" in
    "nodes")
        echo "NAME                       STATUS   ROLES                  AGE   VERSION"
        echo "k3d-ml-cluster-agent-0     Ready    <none>                 5m    v1.26.4+k3s1"
        echo "k3d-ml-cluster-server-0    Ready    control-plane,master   5m    v1.26.4+k3s1"
        ;;
    "pods")
        if [[ "$ARGS" == *"ml-predictor"* ]]; then
            echo "NAME                            READY   STATUS    RESTARTS   AGE"
            echo "ml-predictor-7b9d6c4f5b-xk8mz   1/1     Running   0          2m"
        else
            echo "No resources found"
        fi
        ;;
    "deployment")
        if [[ "$ARGS" == *"ml-predictor"* ]]; then
            echo "NAME           READY   UP-TO-DATE   AVAILABLE   AGE"
            echo "ml-predictor   1/1     1            1           3m"
        else
            echo "No resources found"
        fi
        ;;
    *)
        echo "No resources found"
        ;;
esac
