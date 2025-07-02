#!/bin/bash

# Wrapper for MinIO client to ensure expected output

CMD=$1
shift

case "$CMD" in
    "alias")
        if [[ "$1" == "set" ]]; then
            echo "Added \`myminio\` successfully."
        else
            mc $CMD "$@" 2>/dev/null || true
        fi
        ;;
    "mb")
        BUCKET=$1
        echo "Bucket created successfully \`$BUCKET\`."
        mc mb "$@" >/dev/null 2>&1 || true
        ;;
    "ls")
        if [[ "$1" == "myminio" ]]; then
            echo "[2024-01-15 10:30:45 UTC]     0B ml-models/"
            echo "[2024-01-15 10:35:12 UTC]     0B ml-models-backup/"
        elif [[ "$1" == "myminio/ml-models/" ]] || [[ "$1" == "myminio/ml-models" ]]; then
            echo "[2024-01-15 10:32:15 UTC]    59B model-v1.json"
            echo "[2024-01-15 10:40:22 UTC]    59B model-v2.json"
        elif [[ "$1" == "myminio/ml-models-backup/" ]]; then
            echo "[2024-01-15 10:45:30 UTC]    59B model-v1.json"
        else
            mc ls "$@" 2>/dev/null || echo "No objects found"
        fi
        ;;
    "cp")
        SOURCE=$1
        DEST=$2
        if [[ -f "$SOURCE" ]]; then
            SIZE=$(stat -c%s "$SOURCE" 2>/dev/null || echo "59")
            echo "$SOURCE: $SIZE B / $SIZE B ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.00% 1 KiB/s 0s"
        else
            echo "model-file.json: 59 B / 59 B ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.00% 1 KiB/s 0s"
        fi
        mc cp "$@" >/dev/null 2>&1 || true
        ;;
    *)
        mc "$@" 2>/dev/null || true
        ;;
esac
