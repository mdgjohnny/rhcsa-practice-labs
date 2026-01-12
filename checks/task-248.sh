#!/usr/bin/env bash
# Task: Create /root/listusers.sh that reads /etc/passwd and prints only usernames (first field) using a while loop.
# Title: Shell Script - While Read Loop
# Category: shell-scripts
# Target: node1

check '[[ -x /root/listusers.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "while.*read" /root/listusers.sh' \
    "Script uses while read loop" \
    "No while read loop found"

check '/root/listusers.sh 2>/dev/null | grep -q "root"' \
    "Script outputs root user" \
    "root user not in output"
