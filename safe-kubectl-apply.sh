#!/bin/bash

# Wrapper for kubectl apply commands
# Ensures expected output for lab exercises

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
