#!/usr/bin/env bash
# Task: Create users user100, user200, user300 with home directories. Export their home directories via NFS. Configure autofs indirect mapping so that /home1/user100, /home1/user200, /home1/user300 automatically mount the respective NFS shares.
# Title: NFS Autofs Home Directories
# Category: file-systems
# Target: node1

check 'id user100 &>/dev/null' \
    "User user100 exists" \
    "User user100 does not exist"

check 'id user200 &>/dev/null' \
    "User user200 exists" \
    "User user200 does not exist"

check 'id user300 &>/dev/null' \
    "User user300 exists" \
    "User user300 does not exist"

check 'systemctl is-active nfs-server &>/dev/null' \
    "NFS server is running" \
    "NFS server is not running"

check 'exportfs -v 2>/dev/null | grep -qE "user100|user200|user300|/home"' \
    "Home directories are exported via NFS" \
    "Home directories not exported"

check 'grep -q "/home1" /etc/auto.master 2>/dev/null || grep -qr "/home1" /etc/auto.master.d/ 2>/dev/null' \
    "Autofs configured for /home1" \
    "Autofs not configured for /home1"

check 'systemctl is-active autofs &>/dev/null' \
    "Autofs service is running" \
    "Autofs service is not running"
