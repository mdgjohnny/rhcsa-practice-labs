#!/usr/bin/env bash
# Task: Export /share1 on rhcsa1 and mount it to /share2 on rhcsa2 persistently

check '[[ -d /share1 ]]' \
    "Directory /share1 exists on node1" \
    "Directory /share1 does not exist on node1"

check 'grep -q "/share1" /etc/exports 2>/dev/null' \
    "/share1 is configured in /etc/exports" \
    "/share1 is not configured in /etc/exports"

check 'exportfs -v | grep -q share1' \
    "/share1 is actively exported" \
    "/share1 is not actively exported"

# Check node2 mount via SSH
check 'ssh $SSH_OPTS "$NODE2_IP" "mount | grep -q /share2" 2>/dev/null' \
    "/share2 is mounted on node2" \
    "/share2 is not mounted on node2"

check 'ssh $SSH_OPTS "$NODE2_IP" "grep -q share2 /etc/fstab" 2>/dev/null' \
    "/share2 is configured in node2 /etc/fstab" \
    "/share2 is not in node2 /etc/fstab (not persistent)"
