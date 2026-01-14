#!/usr/bin/env bash
# Task: Find SELinux denials in the audit log and analyze them. Save your analysis showing what's being denied and recommended solutions to /root/selinux-audit.txt.
# Title: Analyze SELinux Audit Denials
# Category: security
# Target: node1

check '[[ -f /root/selinux-audit.txt ]]' \
    "File /root/selinux-audit.txt exists" \
    "File not found"

check '[[ -s /root/selinux-audit.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qiE "denied|avc|scontext|tcontext|boolean|allow" /root/selinux-audit.txt' \
    "File contains SELinux-related analysis" \
    "File doesn't appear to contain SELinux analysis"
