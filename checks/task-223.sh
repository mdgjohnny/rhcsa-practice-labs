#!/usr/bin/env bash
# Task: Use audit2why or sealert to analyze recent SELinux denials. Save the analysis to /root/selinux-audit.txt.
# Title: Analyze SELinux Audit Log
# Category: security
# Target: node1

check '[[ -f /root/selinux-audit.txt ]]' \
    "File /root/selinux-audit.txt exists" \
    "File not found"

# Check for either denials found or no denials message
check 'grep -qiE "denied|allow|scontext|no matches|nothing to do" /root/selinux-audit.txt' \
    "File contains audit analysis" \
    "No audit analysis found"
