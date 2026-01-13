#!/usr/bin/env bash
# Task: Create /dir1/dir2/dir3/dir4 directory structure with SELinux contexts matching /etc.
# Title: Apply SELinux Contexts
# Category: security
# Target: node1


check '[[ -d /dir1/dir2/dir3/dir4 ]]' \
    "Directory hierarchy exists" \
    "Directory hierarchy does not exist"

check 'ls -Zd /dir1 2>/dev/null | grep -q "etc_t"' \
    "/dir1 has correct SELinux context" \
    "/dir1 does not have correct context"

check 'ls -Zd /dir1/dir2/dir3/dir4 2>/dev/null | grep -q "etc_t"' \
    "/dir1/dir2/dir3/dir4 has correct SELinux context" \
    "/dir1/dir2/dir3/dir4 does not have correct context"

check 'semanage fcontext -l | grep -q "/dir1"' \
    "SELinux context rule is persistent" \
    "SELinux context rule not persistent"
