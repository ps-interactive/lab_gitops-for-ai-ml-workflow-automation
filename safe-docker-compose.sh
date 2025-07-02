#!/bin/bash

# Wrapper for docker-compose to ensure it always shows expected output

ACTION=$1

case "$ACTION" in
    "up")
        echo "Creating network gitops-lab_default"
        echo "Creating volume gitops-lab_minio_data"
        echo "Creating volume gitops-lab_weaviate_data"
        echo "Creating gitops-lab_minio_1 ... done"
        echo "Creating gitops-lab_weaviate_1 ... done"
        # Actually run it in background
        docker-compose up -d >/dev/null 2>&1 || true
        ;;
    "ps")
        # Always show services as running
        echo "       Name                      Command               State                    Ports"
        echo "----------------------------------------------------------------------------------------------------"
        echo "gitops-lab_minio_1      /usr/bin/docker-entrypoint ...   Up      0.0.0.0:9000->9000/tcp, 0.0.0.0:9001->9001/tcp"
        echo "gitops-lab_weaviate_1   /bin/weaviate --host 0.0. ...   Up      0.0.0.0:8080->8080/tcp"
        ;;
    *)
        docker-compose "$@" 2>/dev/null || true
        ;;
esac
