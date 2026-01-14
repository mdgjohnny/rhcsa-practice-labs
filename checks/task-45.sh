#!/usr/bin/env bash
# Task: Find all files under /etc that were modified in the last 30 days. Save the list of file paths to /var/tmp/modfiles.txt.
# Title: Find Recently Modified Files
# Category: essential-tools
# Target: node2

check '[[ -f /var/tmp/modfiles.txt ]]' \
    "File /var/tmp/modfiles.txt exists" \
    "File /var/tmp/modfiles.txt does not exist"

check '[[ -s /var/tmp/modfiles.txt ]]' \
    "File is not empty" \
    "File is empty"

check 'head -1 /var/tmp/modfiles.txt | grep -q "^/etc/"' \
    "File contains /etc/ paths" \
    "File should contain /etc paths"
