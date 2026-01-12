#!/usr/bin/env bash
# Task: Enable the SELinux boolean "httpd_enable_homedirs" persistently to allow Apache to serve content from user home directories.
# Title: Enable Apache Home Dirs Boolean
# Category: security
# Target: node1

check 'getsebool httpd_enable_homedirs 2>/dev/null | grep -q "on"' \
    "httpd_enable_homedirs is enabled" \
    "httpd_enable_homedirs is not enabled"
