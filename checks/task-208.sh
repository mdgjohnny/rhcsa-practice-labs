#!/usr/bin/env bash
# Task: The system is in permissive mode. Set it back to enforcing mode both immediately and persistently.
# Title: Restore SELinux Enforcing Mode
# Category: security
# Target: node1

check 'getenforce | grep -qi enforcing' \
    "SELinux is currently enforcing" \
    "SELinux is not enforcing"

check 'grep -qE "^SELINUX=enforcing" /etc/selinux/config' \
    "SELinux config set to enforcing" \
    "SELinux config not set to enforcing"
