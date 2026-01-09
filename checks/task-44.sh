#!/usr/bin/env bash
# Task: Create /dir1/dir2/dir3/dir4 with SELinux contexts of /etc
# Title: Apply SELinux Contexts
# Category: security
# Target: node2

check '[[ -d /dir1/dir2/dir3/dir4 ]]' \
    "Directory hierarchy exists" \
    "Directory hierarchy does not exist"

check 'ls -Zd /dir1 2>/dev/null | grep -q etc_t' \
    "/dir1 has etc_t SELinux context" \
    "/dir1 does not have etc_t SELinux context"
