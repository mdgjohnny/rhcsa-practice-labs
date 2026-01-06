#!/usr/bin/env bash
# Task: Create /direct01 with SELinux contexts from /root (persistent)
# Category: security

check \'run_ssh "$NODE1_IP" "test -d /direct01"\' \
    "Directory /direct01 exists" \
    "Directory /direct01 does not exist"

check \'run_ssh "$NODE1_IP" "ls -Zd /direct01 2>/dev/null | grep -q "admin_home_t\|root_t""\' \
    "/direct01 has /root SELinux context" \
    "/direct01 does not have /root SELinux context"

check \'run_ssh "$NODE1_IP" "semanage fcontext -l | grep -q "/direct01""\' \
    "/direct01 SELinux context is persistent" \
    "/direct01 SELinux context is not persistent"
