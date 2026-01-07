#!/usr/bin/env bash
# Task: Set system timezone to America/New_York on node1
# Title: Set System Timezone
# Category: deploy-maintain

TIMEZONE=$(timedatectl show | awk -F'=' '/Timezone/ {print $2}')
EXPECTED_TIMEZONE="America/New_York"

check '[[ "$TIMEZONE" == "$EXPECTED_TIMEZONE" ]]' \
    "Local timezone has been set to $EXPECTED_TIMEZONE" \
    "Local timezone has not been set to $EXPECTED_TIMEZONE (got $TIMEZONE)"
