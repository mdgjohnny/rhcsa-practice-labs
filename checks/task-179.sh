#!/usr/bin/env bash
# Task: Extract all lines from /etc/passwd where the username starts with "s" and save to /root/s-users.txt. Use grep with a regular expression.
# Title: Filter with Regular Expressions
# Category: essential-tools
# Target: node1

check '[[ -f /root/s-users.txt ]]' \
    "File /root/s-users.txt exists" \
    "File /root/s-users.txt not found"

check '[[ -s /root/s-users.txt ]]' \
    "File has content" \
    "File is empty"

# File should contain users starting with 's' like sshd, sync, etc
check 'grep -qE "^s[a-z]*:" /root/s-users.txt' \
    "File contains usernames starting with s" \
    "File doesn't appear to contain users starting with s"

# Verify it's actual passwd format
check 'head -1 /root/s-users.txt | grep -qE "^[^:]+:[^:]*:[0-9]+:[0-9]+:"' \
    "File is in passwd format" \
    "File doesn't look like passwd output"
