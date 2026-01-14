#!/usr/bin/env bash
# Task: Create file /usr/testfile1. Set its SELinux type to shadow_t and make the context persistent (survives relabeling).
# Title: Set Persistent SELinux File Context
# Category: security
# Target: node1

check '[[ -f /usr/testfile1 ]]' \
    "File /usr/testfile1 exists" \
    "File /usr/testfile1 does not exist"

check 'ls -Z /usr/testfile1 2>/dev/null | grep -q shadow_t' \
    "/usr/testfile1 has shadow_t context" \
    "/usr/testfile1 does not have shadow_t context"

check 'semanage fcontext -l | grep -qE "/usr/testfile1.*shadow_t"' \
    "shadow_t context is persistent (in semanage)" \
    "Context not persistent - use semanage fcontext -a"
