#!/usr/bin/env bash
# Task: Enable the SELinux boolean "ftpd_full_access" to allow FTP to read/write all files. Make it persistent.
# Title: Enable FTP Full Access Boolean
# Category: security
# Target: node1

check 'getsebool ftpd_full_access 2>/dev/null | grep -q "on"' \
    "ftpd_full_access is enabled" \
    "ftpd_full_access is not enabled"
