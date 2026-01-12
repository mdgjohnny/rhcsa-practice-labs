#!/usr/bin/env bash
# Task: Create a script /root/diskusage.sh that displays the percentage of disk usage for the root filesystem. The script should extract and display only the percentage number (e.g., "45" not "45%").
# Title: Shell Script - Process Command Output
# Category: shell-scripts
# Target: node1

check '[[ -f /root/diskusage.sh ]]' \
    "Script /root/diskusage.sh exists" \
    "Script /root/diskusage.sh not found"

check '[[ -x /root/diskusage.sh ]]' \
    "Script is executable" \
    "Script is not executable"

check 'head -1 /root/diskusage.sh | grep -qE "^#!"' \
    "Script has shebang line" \
    "Script missing shebang line"

check 'grep -qE "\\\$\(|`" /root/diskusage.sh' \
    "Script uses command substitution" \
    "Script missing command substitution"

check 'grep -qE "df|awk|cut|sed|grep" /root/diskusage.sh' \
    "Script uses disk/text processing commands" \
    "Script missing df or text processing"

check 'result=$(/root/diskusage.sh 2>/dev/null) && [[ "$result" =~ ^[0-9]+$ ]]' \
    "Script outputs a number only" \
    "Script output is not a plain number"

check 'result=$(/root/diskusage.sh 2>/dev/null) && actual=$(df / | awk "NR==2 {gsub(/%/,\"\"); print \$5}") && [[ "$result" == "$actual" ]]' \
    "Script outputs correct disk usage percentage" \
    "Script outputs incorrect percentage"
