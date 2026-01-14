#!/usr/bin/env bash
# Task: The security team requires SELinux to run in permissive mode on this system for application compatibility testing. Configure SELinux to boot in permissive mode. The change must persist across reboots.
# Title: Configure SELinux Permissive Mode
# Category: security
# Target: node2

check 'grep -qE "^SELINUX=permissive" /etc/selinux/config 2>/dev/null' \
    "SELinux configured for permissive mode at boot" \
    "SELinux not configured for permissive in /etc/selinux/config"

check 'getenforce 2>/dev/null | grep -qi permissive' \
    "SELinux is currently in permissive mode" \
    "SELinux is not currently permissive (may need reboot or setenforce 0)"
