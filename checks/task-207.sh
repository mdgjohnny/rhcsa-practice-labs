#!/usr/bin/env bash
# Task: A process is being blocked by SELinux but you're not sure why. Use the audit log to identify the most recent SELinux denial and save the denial message (the line containing "denied") to /root/selinux-denial.txt. Then use audit2why to analyze it and append the explanation to the same file.
# Title: Analyze SELinux Denials
# Category: security
# Target: node1

# Setup: Generate an SELinux denial to analyze
if ! grep -q "denied" /var/log/audit/audit.log 2>/dev/null; then
    # Try to trigger a denial by accessing something httpd shouldn't
    timeout 2 runcon -t httpd_t -- cat /etc/shadow &>/dev/null || true
fi

check '[[ -f /root/selinux-denial.txt ]]' \
    "File /root/selinux-denial.txt exists" \
    "File /root/selinux-denial.txt not found"

check 'grep -qi "denied" /root/selinux-denial.txt 2>/dev/null' \
    "File contains SELinux denial message" \
    "File doesn't contain a denial message (hint: grep denied /var/log/audit/audit.log)"

check 'grep -qiE "was caused by|requires|boolean|allow" /root/selinux-denial.txt 2>/dev/null' \
    "File contains audit2why analysis" \
    "File missing audit2why explanation (hint: pipe denial to audit2why)"
