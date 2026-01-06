#!/usr/bin/env bash
# Task: Configure NFS server sharing /home on node2
# Category: networking
# Target: node2

# Check if NFS server is installed and running
check 'systemctl is-active nfs-server &>/dev/null' \
    "NFS server is running" \
    "NFS server is not running"

# Check if /home is exported
check 'grep -q "^/home" /etc/exports' \
    "/home is configured in /etc/exports" \
    "/home is not in /etc/exports"

# Check if export is active
check 'exportfs -v 2>/dev/null | grep -q "/home"' \
    "/home is actively exported" \
    "/home is not actively exported"
