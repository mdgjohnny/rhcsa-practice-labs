#!/usr/bin/env bash
# Task: List all SELinux contexts for files in /var/log/. Save the output to /root/varlog-contexts.txt.
# Title: List Log File SELinux Contexts
# Category: security
# Target: node1

check '[[ -f /root/varlog-contexts.txt ]]' \
    "File /root/varlog-contexts.txt exists" \
    "File not found"

check 'grep -qE "var_log_t|system_u" /root/varlog-contexts.txt' \
    "File contains log file contexts" \
    "Expected log contexts not found"

check '[[ $(wc -l < /root/varlog-contexts.txt) -gt 5 ]]' \
    "File has multiple entries" \
    "File should have more entries"
