#!/usr/bin/env bash
# Task: Configure SELinux to be in permissive mode permanently. The change should persist across reboots.
# Title: Set SELinux Permissive Permanently
# Category: security
# Target: node1

check 'grep -qE "^SELINUX=permissive" /etc/selinux/config' \
    "SELinux config set to permissive" \
    "SELinux config not set to permissive"
