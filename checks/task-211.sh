#!/usr/bin/env bash
# Task: Find the SELinux context of the httpd process (if running) or the crond process. Save to /root/process-context.txt.
# Title: List Process SELinux Context
# Category: security
# Target: node1

check '[[ -f /root/process-context.txt ]]' \
    "File /root/process-context.txt exists" \
    "File not found"

check 'grep -qE "httpd_t|crond_t|system_u" /root/process-context.txt' \
    "File contains process context" \
    "Expected process context not found"
