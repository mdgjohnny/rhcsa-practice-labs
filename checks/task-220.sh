#!/usr/bin/env bash
# Task: The FTP server is unable to read/write files outside its default directories due to SELinux. Find and enable the boolean that grants FTP full filesystem access. The setting must survive reboots.
# Title: Fix FTP Filesystem Access (SELinux)
# Category: security
# Target: node1

check 'getsebool ftpd_full_access 2>/dev/null | grep -q "on"' \
    "ftpd_full_access is enabled" \
    "ftpd_full_access is not enabled"
