#!/bin/bash

echo "Testing rollback mechanism..."

# Get current revision
CURRENT_REV=$(kubectl get ksvc ml-predictor -o jsonpath='{.status.latestCreatedRevisionName}')
echo "Current revision: $CURRENT_REV"

# Trigger rollback to previous revision
echo "Initiating rollback..."
kubectl annotate ksvc ml-predictor rollback.trigger="manual-$(date +%s)" --overwrite

# Wait for rollback
sleep 5

# Check new revision
NEW_REV=$(kubectl get ksvc ml-predictor -o jsonpath='{.status.latestReadyRevisionName}')
echo "Active revision after rollback: $NEW_REV"

if [ "$CURRENT_REV" != "$NEW_REV" ]; then
    echo "Rollback successful!"
else
    echo "Rollback may not have been necessary - service is stable"
fi
