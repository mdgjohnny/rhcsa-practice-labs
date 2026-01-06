#!/usr/bin/env bash
# Task: Create /var/dir1 with full permissions, sticky bit
# Category: file-systems
# Non-owners cannot delete files

check \'run_ssh "$NODE1_IP" "test -d /var/dir1"\' \
    "Directory /var/dir1 exists" \
    "Directory /var/dir1 does not exist"

check \'run_ssh "$NODE1_IP" "stat -c %a /var/dir1 | grep -q "^1777\|^3777""\' \
    "/var/dir1 has sticky bit and full permissions" \
    "/var/dir1 does not have correct permissions"
