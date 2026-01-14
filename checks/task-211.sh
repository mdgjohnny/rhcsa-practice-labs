#!/usr/bin/env bash
# Task: Find the SELinux context of the sshd process using ps -Z. Save the full context line (with PID, context, and process name) to /root/process-context.txt.
# Title: Find Process SELinux Context
# Category: security
# Target: node1

check '[[ -f /root/process-context.txt ]]' \
    "File /root/process-context.txt exists" \
    "File not found"

check '[[ -s /root/process-context.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qE "sshd_t" /root/process-context.txt' \
    "File contains sshd_t context" \
    "sshd_t context not found (use: ps -Z | grep sshd)"

check 'grep -qE "[0-9]+.*sshd" /root/process-context.txt' \
    "File contains PID and process name" \
    "Missing PID or process name"
