#!/usr/bin/env bash
# Task: Find all files owned by user "linda" and copy them to directory /tmp/lindafiles/. Preserve file attributes using cp -p.
# Title: Find Files by Owner
# Category: essential-tools
# Target: node1

# Check directory exists
check '[[ -d /tmp/lindafiles ]]' \
    "Directory /tmp/lindafiles/ exists" \
    "Directory /tmp/lindafiles/ does not exist"

# Check it contains files
check '[[ $(ls -A /tmp/lindafiles/ 2>/dev/null | wc -l) -gt 0 ]]' \
    "Directory /tmp/lindafiles/ contains files" \
    "Directory /tmp/lindafiles/ is empty"
