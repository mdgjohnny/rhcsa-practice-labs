#!/usr/bin/env bash
# Task: NFS clients can mount exports as read-only but write operations fail due to SELinux. Find and enable the SELinux boolean that allows NFS to export filesystems with read-write access. The change must persist across reboots.
# Title: Fix NFS Read-Write Exports (SELinux)
# Category: security
# Target: node1

check 'getsebool nfs_export_all_rw 2>/dev/null | grep -q "on"' \
    "nfs_export_all_rw boolean is enabled" \
    "nfs_export_all_rw boolean is not enabled"
