#!/usr/bin/env bash
# Task: Schedule a job using 'at' to create file /tmp/scheduled-job at a time 5 minutes from now.
# Title: Schedule One-time Job with at
# Category: deploy-maintain
# Target: node1

check 'systemctl is-active atd &>/dev/null' \
    "atd service is running" \
    "atd service not running"

check 'atq | grep -qE "[0-9]+" || at -l | grep -qE "[0-9]+"' \
    "Job is scheduled in at queue" \
    "No job found in at queue"
