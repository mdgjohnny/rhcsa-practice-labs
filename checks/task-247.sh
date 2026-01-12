#!/usr/bin/env bash
# Task: Create /root/checkfile.sh that takes a filename argument and reports if it's readable, writable, or executable using test operators.
# Title: Shell Script - File Permission Check
# Category: shell-scripts
# Target: node1

check '[[ -x /root/checkfile.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "(-r |-w |-x )" /root/checkfile.sh' \
    "Script uses file test operators" \
    "No file test operators found"

check '/root/checkfile.sh /etc/passwd 2>/dev/null | grep -qi "read"' \
    "Script identifies readable files" \
    "Script doesn't check readability correctly"
