#!/usr/bin/env bash
# Task: Check the current SELinux mode and policy type. Save the output to /root/selinux-status.txt showing both mode and policy.
# Title: Check SELinux Status
# Category: security
# Target: node1

check '[[ -f /root/selinux-status.txt ]]' \
    "File /root/selinux-status.txt exists" \
    "File not found"

check 'grep -qiE "enforcing|permissive|disabled" /root/selinux-status.txt' \
    "File contains SELinux mode" \
    "SELinux mode not found in file"

check 'grep -qi "targeted" /root/selinux-status.txt' \
    "File contains policy type" \
    "Policy type not found in file"
