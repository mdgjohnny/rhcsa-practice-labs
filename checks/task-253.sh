#!/usr/bin/env bash
# Task: Create /root/usercount.sh that counts the number of lines in /etc/passwd and outputs "There are X users on the system" where X is the count.
# Title: Shell Script - Count Users
# Category: shell-scripts
# Target: node1

check '[[ -x /root/usercount.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "/etc/passwd" /root/usercount.sh' \
    "Script references /etc/passwd" \
    "Script doesn't read /etc/passwd"

check '/root/usercount.sh 2>/dev/null | grep -qiE "[0-9]+ users"' \
    "Output contains user count" \
    "Output doesn't show user count"

# Verify count is reasonable (system has at least 10 users typically)
check '[[ $(/root/usercount.sh 2>/dev/null | grep -oE "[0-9]+" | head -1) -ge 10 ]]' \
    "Count is reasonable (≥10)" \
    "Count seems too low"
