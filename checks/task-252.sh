#!/usr/bin/env bash
# Task: Create /root/meminfo.sh that extracts and displays total and free memory from /proc/meminfo using command substitution.
# Title: Shell Script - Memory Information
# Category: shell-scripts
# Target: node1

check '[[ -x /root/meminfo.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "\\\$\(.*\)|`.*`" /root/meminfo.sh' \
    "Script uses command substitution" \
    "No command substitution found"

check '/root/meminfo.sh 2>/dev/null | grep -qiE "mem|total|free"' \
    "Script outputs memory information" \
    "No memory info in output"
