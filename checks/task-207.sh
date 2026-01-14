#!/usr/bin/env bash
# Task: Find an SELinux denial in the audit log (there should be at least one from httpd). Save the denial line to /root/selinux-denial.txt. Then use audit2why to analyze it and append the explanation to the same file.
# Title: Analyze SELinux Denials with audit2why
# Category: security
# Target: node1

check '[[ -f /root/selinux-denial.txt ]]' \
    "File /root/selinux-denial.txt exists" \
    "File /root/selinux-denial.txt not found"

check 'grep -qi "denied" /root/selinux-denial.txt 2>/dev/null' \
    "File contains SELinux denial message" \
    "File doesn't contain a denial (search audit.log for 'denied')"

check 'grep -qiE "was caused by|requires|boolean|allow|scontext" /root/selinux-denial.txt 2>/dev/null' \
    "File contains audit2why analysis" \
    "Missing audit2why explanation"
