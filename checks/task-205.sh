#!/usr/bin/env bash
# Task: Create a system cron job in /etc/cron.d/cleanup that runs /usr/local/bin/cleanup.sh every day at 3:30 AM as root.
# Title: Create System Cron Job
# Category: deploy-maintain
# Target: node1

check '[[ -f /etc/cron.d/cleanup ]]' \
    "Cron file /etc/cron.d/cleanup exists" \
    "Cron file not found"

check 'grep -qE "30\s+3\s+\*\s+\*\s+\*.*root.*/usr/local/bin/cleanup.sh" /etc/cron.d/cleanup' \
    "Cron job runs at 3:30 AM daily as root" \
    "Cron schedule incorrect"
