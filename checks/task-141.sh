#!/usr/bin/env bash
# Task: Set SELinux to permissive mode
# Category: security
# Target: node1


check \'run_ssh "$NODE1_IP" "getenforce | grep -qi permissive"\' \
    "SELinux is in permissive mode" \
    "SELinux is not in permissive mode"
