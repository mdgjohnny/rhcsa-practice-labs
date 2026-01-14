#!/usr/bin/env bash
# Task: A previous administrator disabled SELinux enforcement for troubleshooting and forgot to re-enable it. Restore SELinux to enforcing mode both immediately and persistently.
# Title: Restore SELinux Enforcing Mode
# Category: security
# Target: node1

check 'grep -qE "^SELINUX=enforcing" /etc/selinux/config 2>/dev/null' \
    "SELinux configured for enforcing mode at boot" \
    "SELinux not configured for enforcing in /etc/selinux/config"

check 'getenforce 2>/dev/null | grep -qi enforcing' \
    "SELinux is currently enforcing" \
    "SELinux is not currently enforcing"
