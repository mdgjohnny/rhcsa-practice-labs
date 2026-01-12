#!/usr/bin/env bash
# Task: Use ausearch to find SELinux denials in the audit log from today. Save results to /root/denials.txt.
# Title: Search SELinux Audit Denials
# Category: security
# Target: node1

check '[[ -f /root/denials.txt ]]' \
    "Denials file exists" \
    "File not found"
