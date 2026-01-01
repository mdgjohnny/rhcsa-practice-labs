#!/usr/bin/env bash
# Task: Set SELinux type shadow_t on /usr/testfile1
# Category: security
# Context should survive relabeling

check '[[ -f /usr/testfile1 ]]' \
    "File /usr/testfile1 exists" \
    "File /usr/testfile1 does not exist"

check 'ls -Z /usr/testfile1 2>/dev/null | grep -q shadow_t' \
    "/usr/testfile1 has shadow_t context" \
    "/usr/testfile1 does not have shadow_t context"

check 'semanage fcontext -l | grep -q "/usr/testfile1.*shadow_t"' \
    "shadow_t context is persistent for /usr/testfile1" \
    "shadow_t context is not persistent"
