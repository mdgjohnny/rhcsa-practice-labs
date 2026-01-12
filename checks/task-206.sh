#!/usr/bin/env bash
# Task: Set SELinux to permissive mode temporarily (until next reboot). Do not modify the config file.
# Title: Set SELinux Permissive Temporarily
# Category: security
# Target: node1

check 'getenforce | grep -qi permissive' \
    "SELinux is in permissive mode" \
    "SELinux is not in permissive mode"

check 'grep -q "^SELINUX=enforcing" /etc/selinux/config' \
    "Config file still set to enforcing (temporary change)" \
    "Config file was modified (should remain enforcing)"
