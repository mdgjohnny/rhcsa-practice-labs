#!/usr/bin/env bash
# Task: Find all SUID files and save list to /root/suidfiles
# Category: users-groups
# Target: node1

# Check if the output file exists
check '[[ -f /root/suidfiles ]]' \
    "File /root/suidfiles exists" \
    "File /root/suidfiles does not exist"

# Check if file contains SUID files (should have entries like /usr/bin/passwd)
check 'grep -q "/usr/bin/passwd\|/usr/bin/sudo\|/bin/su" /root/suidfiles 2>/dev/null' \
    "/root/suidfiles contains common SUID files" \
    "/root/suidfiles appears empty or incomplete"
