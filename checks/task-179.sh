#!/usr/bin/env bash
# Task: Extract all lines from /etc/passwd where the username starts with "s" and ends with a digit. Save the output to /root/s-users.txt.
# Title: Filter with Regular Expressions
# Category: essential-tools
# Target: node1

check '[[ -f /root/s-users.txt ]]' \
    "File /root/s-users.txt exists" \
    "File /root/s-users.txt not found"

# Create a test user matching pattern if none exist
check 'useradd student1 2>/dev/null; grep -E "^s.*[0-9]:" /etc/passwd | diff - /root/s-users.txt &>/dev/null' \
    "File contains correct filtered output" \
    "File content doesn't match expected pattern (^s.*[0-9]:)"
