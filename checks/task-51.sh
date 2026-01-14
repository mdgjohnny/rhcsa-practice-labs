#!/usr/bin/env bash
# Task: You are setting up an NFS server that needs to export directories with read-write access. SELinux restricts NFS exports to read-only by default. Find and enable the boolean that allows NFS to export with full read-write permissions. The change must persist across reboots.
# Title: Fix NFS Read-Write Exports (SELinux)
# Category: security
# Target: node1

check 'getsebool nfs_export_all_rw 2>/dev/null | grep -q "on"' \
    "Correct SELinux boolean is enabled" \
    "Required boolean is not enabled (hint: search nfs booleans)"
