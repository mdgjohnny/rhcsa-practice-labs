#!/usr/bin/env bash
# Task: Create directory /direct01 and apply the same SELinux context as /root. Context must persist after relabeling.
# Title: Apply SELinux Contexts
# Category: security

check '[[ -d /direct01 ]]' \
    "Directory /direct01 exists" \
    "Directory /direct01 does not exist"

check 'ls -Zd /direct01 2>/dev/null | grep -q "admin_home_t\|root_t"' \
    "/direct01 has /root SELinux context" \
    "/direct01 does not have /root SELinux context"

check 'semanage fcontext -l | grep -q "/direct01"' \
    "/direct01 SELinux context is persistent" \
    "/direct01 SELinux context is not persistent"
