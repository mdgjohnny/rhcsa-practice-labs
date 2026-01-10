#!/usr/bin/env bash
# Task: Create /share1 directory and export it via NFS. Ensure nfs-server service is running.
# Title: Export Directory via NFS
# Category: file-systems
# Target: node1

check '[[ -d /share1 ]]' \
    "Directory /share1 exists" \
    "Directory /share1 does not exist"

check 'grep -q "/share1" /etc/exports 2>/dev/null' \
    "/share1 is configured in /etc/exports" \
    "/share1 is not configured in /etc/exports"

check 'exportfs -v | grep -q share1' \
    "/share1 is actively exported" \
    "/share1 is not actively exported"
