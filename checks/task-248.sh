#!/usr/bin/env bash
# Task: Create /root/listusers.sh that reads /etc/passwd and prints only usernames (first field) using a while read loop.
# Title: Shell Script - While Read Loop
# Category: shell-scripts
# Target: node1

check '[[ -x /root/listusers.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "while.*read" /root/listusers.sh' \
    "Script uses while read loop" \
    "No while read loop found"

check 'grep -qE "/etc/passwd" /root/listusers.sh' \
    "Script references /etc/passwd" \
    "Script doesn't read /etc/passwd"

check '/root/listusers.sh 2>/dev/null | grep -q "^root$"' \
    "Script outputs root user (as standalone line)" \
    "root user not correctly in output"

check '[[ $(/root/listusers.sh 2>/dev/null | wc -l) -gt 5 ]]' \
    "Script outputs multiple users" \
    "Script doesn't output enough users"
