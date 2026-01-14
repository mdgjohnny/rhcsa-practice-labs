#!/usr/bin/env bash
# Task: Create /root/system-info.txt containing three pieces of information, each on a separate line: 1) the system hostname, 2) current date, 3) kernel version. Build the file by appending each item.
# Title: Append System Info to File
# Category: essential-tools
# Target: node1

check '[[ -f /root/system-info.txt ]]' \
    "File /root/system-info.txt exists" \
    "File /root/system-info.txt not found"

check 'grep -q "$(hostname)" /root/system-info.txt' \
    "File contains hostname" \
    "Hostname not found in file"

check 'grep -qE "[0-9]{4}" /root/system-info.txt' \
    "File contains date with year" \
    "Date not found in file"

check 'grep -q "$(uname -r)" /root/system-info.txt' \
    "File contains kernel version" \
    "Kernel version not found in file"

check '[[ $(wc -l < /root/system-info.txt) -ge 3 ]]' \
    "File has at least 3 lines" \
    "File should have at least 3 lines"
