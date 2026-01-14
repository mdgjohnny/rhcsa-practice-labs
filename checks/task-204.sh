#!/usr/bin/env bash
# Task: Using the 'at' command, schedule a job that creates /tmp/scheduled-job file. Schedule it for any time in the future (e.g., "now + 5 minutes" or a specific time).
# Title: Schedule One-time Job with at
# Category: deploy-maintain
# Target: node1

check 'systemctl is-active atd &>/dev/null' \
    "atd service is running" \
    "atd service not running"

check 'atq | grep -qE "[0-9]+" || [[ -f /tmp/scheduled-job ]]' \
    "Job is scheduled in at queue or already ran" \
    "No job found in at queue and /tmp/scheduled-job doesn't exist"

# If job already ran, file should exist; if pending, verify queue references the job
check '[[ -f /tmp/scheduled-job ]] || at -c $(atq | head -1 | awk "{print \$1}") 2>/dev/null | grep -q "scheduled-job"' \
    "Job creates /tmp/scheduled-job" \
    "Job doesn't appear to create /tmp/scheduled-job"
