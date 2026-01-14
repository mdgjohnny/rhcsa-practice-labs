#!/usr/bin/env bash
# Task: You need to configure vsftpd to allow users to upload files anywhere on the system (not just their home directories). SELinux restricts this by default. Find and enable the boolean that grants the FTP daemon full read/write access to the filesystem. The setting must survive reboots.
# Title: Fix FTP Filesystem Access (SELinux)
# Category: security
# Target: node1

check 'getsebool ftpd_full_access 2>/dev/null | grep -q "on"' \
    "ftpd_full_access is enabled" \
    "ftpd_full_access is not enabled"
