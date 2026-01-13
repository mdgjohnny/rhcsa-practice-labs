#!/usr/bin/env bash
# Task: Create directory /samba-share. Configure SELinux context so Samba can share files from this directory persistently.
# Title: SELinux Context for Samba Share
# Category: security
# Target: node1


check '[[ -d /samba-share ]]' \
    "Directory /samba-share exists" \
    "Directory /samba-share does not exist"

check 'ls -Zd /samba-share 2>/dev/null | grep -q "samba_share_t"' \
    "/samba-share has correct SELinux context" \
    "/samba-share does not have correct context"

check 'semanage fcontext -l | grep -q "/samba-share"' \
    "SELinux context rule is persistent" \
    "SELinux context rule not persistent"
