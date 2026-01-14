#!/usr/bin/env bash
# Task: Create /share1 directory and export it via NFS with read-write access for all clients. The nfs-server service must be running. Verify from node2 that the share is accessible.
# Title: Export Directory via NFS
# Category: file-systems
# Target: node1

check '[[ -d /share1 ]]' \
    "Directory /share1 exists" \
    "Directory /share1 does not exist"

check 'grep -qE "/share1[[:space:]]" /etc/exports 2>/dev/null' \
    "/share1 is configured in /etc/exports" \
    "/share1 is not configured in /etc/exports"

check 'systemctl is-active nfs-server &>/dev/null' \
    "nfs-server service is running" \
    "nfs-server service is not running"

check 'exportfs -v | grep -q share1' \
    "/share1 is actively exported" \
    "/share1 is not actively exported"
