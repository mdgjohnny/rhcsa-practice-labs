#!/usr/bin/env bash
# Task: Enable the SELinux boolean that allows NFS to export read-write. The change must persist across reboots.
# Title: Toggle SELinux Boolean
# Category: security
# Target: node1

check 'getsebool nfs_export_all_rw 2>/dev/null | grep -q "on"' \
    "nfs_export_all_rw boolean is enabled" \
    "nfs_export_all_rw boolean is not enabled"
