#!/usr/bin/env bash
# Task: Use the tee command to display "System check complete" on screen AND append it to /var/log/mycheck.log at the same time.
# Title: Use tee for Dual Output
# Category: essential-tools
# Target: node1

check '[[ -f /var/log/mycheck.log ]]' \
    "File /var/log/mycheck.log exists" \
    "File /var/log/mycheck.log not found"

check 'grep -q "System check complete" /var/log/mycheck.log' \
    "File contains the message" \
    "Message not found in log file"
