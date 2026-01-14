#!/usr/bin/env bash
# Task: Create /root/meminfo.sh that reads /proc/meminfo and displays the total and free memory. Use command substitution to extract the values.
# Title: Shell Script - Display Memory Info
# Category: shell-scripts
# Target: node1

check '[[ -x /root/meminfo.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "/proc/meminfo" /root/meminfo.sh' \
    "Script reads /proc/meminfo" \
    "Script doesn't reference /proc/meminfo"

check 'grep -qE "\$\(.*\)|\`.*\`" /root/meminfo.sh' \
    "Script uses command substitution" \
    "No command substitution found"

check '/root/meminfo.sh 2>/dev/null | grep -qiE "[0-9]+ ?kB|[0-9]+ ?MB|[0-9]+ ?GB"' \
    "Script outputs memory values" \
    "Output doesn't contain memory values"
