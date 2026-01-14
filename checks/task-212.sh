#!/usr/bin/env bash
# Task: List all files in /var/log/ with their SELinux contexts (use ls -Z). Save the output to /root/varlog-contexts.txt.
# Title: List Log File SELinux Contexts
# Category: security
# Target: node1

check '[[ -f /root/varlog-contexts.txt ]]' \
    "File /root/varlog-contexts.txt exists" \
    "File not found"

check '[[ -s /root/varlog-contexts.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qE "var_log_t|system_u" /root/varlog-contexts.txt' \
    "File contains log file contexts" \
    "Expected SELinux contexts not found"

check '[[ $(wc -l < /root/varlog-contexts.txt) -gt 3 ]]' \
    "File has multiple entries" \
    "File should have more entries"
