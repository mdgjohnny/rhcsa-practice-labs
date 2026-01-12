#!/usr/bin/env bash
# Task: Create /root/usercount.sh that counts total users in /etc/passwd and outputs "There are X users on the system".
# Title: Shell Script - Count and Report
# Category: shell-scripts
# Target: node1

check '[[ -x /root/usercount.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check '/root/usercount.sh 2>/dev/null | grep -qE "[0-9]+ users"' \
    "Script outputs user count" \
    "No user count in output"
