#!/usr/bin/env bash
# Task: Create /var/dir1 with full permissions (777) and sticky bit set.
# Title: Create Directory with Sticky Bit
# Category: file-systems
# Target: node1
# Non-owners cannot delete files

check '[[ -d /var/dir1 ]]' \
    "Directory /var/dir1 exists" \
    "Directory /var/dir1 does not exist"

check 'stat -c %a /var/dir1 | grep -q "^1777\|^3777"' \
    "/var/dir1 has sticky bit and full permissions" \
    "/var/dir1 does not have correct permissions"
