#!/usr/bin/env bash
# Task: You are configuring an NFS server to export directories with full read-write access to remote clients. A security audit has identified that the SELinux boolean controlling NFS read-write exports is disabled, which will cause write failures for remote NFS clients. Enable the correct boolean persistently.
# Title: Configure NFS SELinux Boolean for Read-Write Exports
# Category: security
# Target: node1

# Setup NFS to make the task realistic
if ! rpm -q nfs-utils &>/dev/null; then
    dnf install -y nfs-utils &>/dev/null
fi

mkdir -p /srv/nfsdata
chmod 755 /srv/nfsdata

if ! grep -q "/srv/nfsdata" /etc/exports 2>/dev/null; then
    echo "/srv/nfsdata *(rw,sync,no_root_squash)" >> /etc/exports
fi

systemctl enable --now nfs-server &>/dev/null
exportfs -ra 2>/dev/null

# THE CHECKS
check 'getsebool nfs_export_all_rw 2>/dev/null | grep -q " on$"' \
    "SELinux boolean for NFS read-write exports is enabled" \
    "Required SELinux boolean is not enabled (hint: getsebool -a | grep nfs)"

check 'semanage boolean -l 2>/dev/null | grep "nfs_export_all_rw " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"

check 'exportfs -v 2>/dev/null | grep -q "/srv/nfsdata"' \
    "NFS export is active" \
    "NFS export not configured"
