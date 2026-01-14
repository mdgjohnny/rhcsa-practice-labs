#!/usr/bin/env bash
# Task: Use journalctl to find all log entries from the sshd service since the last boot. Save the output to /root/sshd-logs.txt.
# Title: Query Systemd Journal by Service
# Category: operate-systems
# Target: node1

check '[[ -f /root/sshd-logs.txt ]]' \
    "File /root/sshd-logs.txt exists" \
    "File not found"

# File should be non-empty since sshd logs during boot
check '[[ -s /root/sshd-logs.txt ]]' \
    "File has content" \
    "File is empty (sshd should have boot logs)"

check 'grep -qiE "sshd" /root/sshd-logs.txt' \
    "File contains sshd entries" \
    "File doesn't contain sshd entries"
