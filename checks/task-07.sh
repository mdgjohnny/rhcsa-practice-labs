#!/usr/bin/env bash
# Task: Check whether system time has been set to 'America/New_York' in node1

TIMEZONE=$(timedatectl show | awk -F'=' '/Timezone/ {print $2}')
EXPECTED_TIMEZONE="America/New_York"

check '[[ "$TIMEZONE" == "$EXPECTED_TIMEZONE" ]]' \
    "Local timezone has been set to $EXPECTED_TIMEZONE" \
    "Local timezone has not been set to $EXPECTED_TIMEZONE (got $TIMEZONE)"
