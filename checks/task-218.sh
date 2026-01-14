#!/usr/bin/env bash
# Task: Users are reporting that Apache cannot serve files from their ~/public_html directories despite correct file permissions. This is an SELinux issue. Find and enable the appropriate boolean to allow Apache to access user home directories. Make it persistent.
# Title: Fix Apache User Home Directory Access (SELinux)
# Category: security
# Target: node1

check 'getsebool httpd_enable_homedirs 2>/dev/null | grep -q "on"' \
    "httpd_enable_homedirs is enabled" \
    "httpd_enable_homedirs is not enabled"
