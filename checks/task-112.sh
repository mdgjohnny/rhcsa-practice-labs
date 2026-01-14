#!/usr/bin/env bash
# Task: Find all files with the setuid permission set and copy them to /root/setuid-files/. Use find with the -perm option.
# Title: Find SUID Files
# Category: essential-tools
# Target: node1

check '[[ -d /root/setuid-files ]]' \
    "Directory /root/setuid-files/ exists" \
    "Directory /root/setuid-files/ does not exist"

check '[[ $(ls -A /root/setuid-files/ 2>/dev/null | wc -l) -gt 0 ]]' \
    "Directory /root/setuid-files/ contains files" \
    "Directory /root/setuid-files/ is empty"

# Common setuid files: su, sudo, passwd, ping, etc
check '[[ -f /root/setuid-files/passwd ]] || [[ -f /root/setuid-files/su ]] || [[ -f /root/setuid-files/sudo ]]' \
    "Common SUID files found (passwd, su, or sudo)" \
    "Expected SUID files not found"
