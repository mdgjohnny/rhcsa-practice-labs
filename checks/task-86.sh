#!/usr/bin/env bash
# Task: Set up an NFS server that shares the `/home` directory on `node2`
# Category: networking
# Target: node2

# Check if NFS server is installed and running
check \'run_ssh "$NODE2_IP" "systemctl is-active nfs-server &>/dev/null"\' \
    "NFS server is running" \
    "NFS server is not running"

# Check if /home is exported
check \'run_ssh "$NODE2_IP" "grep -q "^/home" /etc/exports"\' \
    "/home is configured in /etc/exports" \
    "/home is not in /etc/exports"

# Check if export is active
check 'exportfs -v 2>/dev/null | grep -q "/home"' \
    "/home is actively exported" \
    "/home is not actively exported"
