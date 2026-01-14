#!/usr/bin/env bash
# Task: An NFS server is exporting /srv/nfsdata with read-write permissions, but the SELinux boolean for NFS read-write exports is disabled. Enable the correct boolean persistently to allow NFS clients to write to exports.
# Title: Configure NFS SELinux Boolean for Read-Write Exports
# Category: security
# Target: node1

check 'getsebool nfs_export_all_rw 2>/dev/null | grep -q " on$"' \
    "SELinux boolean for NFS read-write exports is enabled" \
    "Required SELinux boolean is not enabled (hint: getsebool -a | grep nfs)"

check 'semanage boolean -l 2>/dev/null | grep "nfs_export_all_rw " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"

check 'exportfs -v 2>/dev/null | grep -q "/srv/nfsdata"' \
    "NFS export is active" \
    "NFS export not configured"
