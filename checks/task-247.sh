#!/usr/bin/env bash
# Task: Create /root/checkfile.sh that takes a filename argument and prints whether the file is readable, writable, and/or executable. Use bash test operators (-r, -w, -x).
# Title: Shell Script - File Permission Check
# Category: shell-scripts
# Target: node1

check '[[ -x /root/checkfile.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "\-r |\-w |\-x " /root/checkfile.sh' \
    "Script uses file test operators (-r, -w, -x)" \
    "No file test operators found"

check '/root/checkfile.sh /etc/passwd 2>/dev/null | grep -qiE "read|r"' \
    "Script identifies readable files" \
    "Script doesn't report readability"

check '/root/checkfile.sh /root/checkfile.sh 2>/dev/null | grep -qiE "exec|x"' \
    "Script identifies executable files" \
    "Script doesn't report executability"
