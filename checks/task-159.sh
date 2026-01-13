#!/usr/bin/env bash
# Task: Create /home/shared directory. Configure SELinux context so NFS can export this directory to clients.
# Title: SELinux Context for NFS Export
# Category: security
# Target: node1


check '[[ -d /home/shared ]]' \
    "Directory /home/shared exists" \
    "Directory /home/shared does not exist"

check 'ls -Zd /home/shared 2>/dev/null | grep -qE "nfs_t|public_content_t"' \
    "/home/shared has correct SELinux context" \
    "/home/shared does not have correct context"

check 'semanage fcontext -l | grep -q "/home/shared"' \
    "SELinux context rule is persistent" \
    "SELinux context rule not persistent"
