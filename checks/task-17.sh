#!/usr/bin/env bash
# Task: Export /share1 on rhcsa1 via NFS
# Title: NFS Export (node1)
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
