#!/usr/bin/env bash
# Task: Find all files with the SetUID bit set on the system. Save the list to /root/suidfiles.
# Title: Find SetUID Files
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
