#!/usr/bin/env bash
# Task: Use journalctl to find all log entries from the sshd service in the last hour. Save the output to /root/sshd-logs.txt.
# Title: Query Systemd Journal
# Category: operate-systems
# Target: node1

check '[[ -f /root/sshd-logs.txt ]]' \
    "File /root/sshd-logs.txt exists" \
    "File not found"

check 'grep -qiE "sshd|ssh" /root/sshd-logs.txt || [[ $(wc -l < /root/sshd-logs.txt) -eq 0 ]]' \
    "File contains sshd entries or is empty (no recent logs)" \
    "File doesn't contain sshd entries"
