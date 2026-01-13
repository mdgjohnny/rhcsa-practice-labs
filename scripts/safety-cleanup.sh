#!/bin/bash
# Safety net cleanup script - run via cron every hour
# Terminates any VMs older than 10 hours regardless of session state
#
# Add to crontab: 0 * * * * /path/to/safety-cleanup.sh >> /var/log/rhcsa-cleanup.log 2>&1

set -e

MAX_AGE_HOURS=10
PROJECT_TAG="rhcsa-practice-labs"

echo "$(date): Running safety cleanup..."

# Check if OCI CLI is available
if ! command -v oci &>/dev/null; then
    echo "OCI CLI not available, skipping"
    exit 0
fi

# Get compartment from config
COMPARTMENT=$(grep compartment_ocid ~/.oci/oci.env 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")
if [ -z "$COMPARTMENT" ]; then
    echo "No compartment configured, skipping"
    exit 0
fi

# Find instances older than MAX_AGE_HOURS with our tag
CUTOFF=$(date -u -d "$MAX_AGE_HOURS hours ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-${MAX_AGE_HOURS}H +%Y-%m-%dT%H:%M:%SZ)

echo "Looking for instances older than $CUTOFF..."

# List running instances with our project tag
INSTANCES=$(oci compute instance list \
    --compartment-id "$COMPARTMENT" \
    --lifecycle-state RUNNING \
    --query "data[?\"freeform-tags\".Project=='$PROJECT_TAG' && \"time-created\"<'$CUTOFF'].id" \
    --output json 2>/dev/null || echo "[]")

if [ "$INSTANCES" = "[]" ] || [ -z "$INSTANCES" ]; then
    echo "No stale instances found"
    exit 0
fi

echo "Found stale instances: $INSTANCES"

# Terminate each
for INSTANCE_ID in $(echo "$INSTANCES" | jq -r '.[]'); do
    echo "Terminating $INSTANCE_ID..."
    oci compute instance terminate --instance-id "$INSTANCE_ID" --force 2>/dev/null || true
done

echo "$(date): Cleanup complete"
