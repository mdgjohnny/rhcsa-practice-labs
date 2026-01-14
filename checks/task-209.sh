#!/usr/bin/env bash
# Task: Document the current SELinux status for an audit report. Save the full SELinux status (mode, policy, and state details) to /root/selinux-status.txt.
# Title: Document SELinux Status
# Category: security
# Target: node1

check '[[ -f /root/selinux-status.txt ]]' \
    "File /root/selinux-status.txt exists" \
    "File /root/selinux-status.txt not found"

check 'grep -qiE "enforcing|permissive|disabled" /root/selinux-status.txt 2>/dev/null' \
    "File contains SELinux mode information" \
    "File missing mode information"

check 'grep -qi "targeted\|mls\|minimum" /root/selinux-status.txt 2>/dev/null' \
    "File contains SELinux policy type" \
    "File missing policy type (hint: sestatus shows this)"
