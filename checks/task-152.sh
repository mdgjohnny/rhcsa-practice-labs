#!/usr/bin/env bash
# Task: Create /dir1/dir2/dir3/dir4 with SELinux contexts from /etc
# Title: Apply SELinux Contexts
# Category: security
# Target: node1

# Check directory hierarchy exists
check '[[ -d /dir1/dir2/dir3/dir4 ]]' \
    "Directory hierarchy /dir1/dir2/dir3/dir4 exists" \
    "Directory hierarchy does not exist"

# Check SELinux context matches /etc (etc_t type)
check 'ls -Zd /dir1 2>/dev/null | grep -q "etc_t"' \
    "/dir1 has etc_t SELinux context" \
    "/dir1 does not have etc_t context"

# Check context is set persistently
check 'semanage fcontext -l | grep -q "/dir1"' \
    "SELinux context is set persistently for /dir1" \
    "SELinux context not persistent"
