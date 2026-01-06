#!/usr/bin/env bash
# Task: Create a directory hierarchy /dir1/dir2/dir3/dir4 and apply SELinux contexts of /etc on it recursively
# Category: security
# Target: node1

# Check directory hierarchy exists
check \'run_ssh "$NODE1_IP" "test -d /dir1/dir2/dir3/dir4"\' \
    "Directory hierarchy /dir1/dir2/dir3/dir4 exists" \
    "Directory hierarchy does not exist"

# Check SELinux context matches /etc (etc_t type)
check \'run_ssh "$NODE1_IP" "ls -Zd /dir1 2>/dev/null | grep -q "etc_t""\' \
    "/dir1 has etc_t SELinux context" \
    "/dir1 does not have etc_t context"

# Check context is set persistently
check \'run_ssh "$NODE1_IP" "semanage fcontext -l | grep -q "/dir1""\' \
    "SELinux context is set persistently for /dir1" \
    "SELinux context not persistent"
