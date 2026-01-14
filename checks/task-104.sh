#!/usr/bin/env bash
# Task: Create /users directory with subdirectories linda and anna. Export /users via NFS with read-write access. On node2, configure autofs to mount /users/linda and /users/anna automatically under /remote/users/ using indirect mapping.
# Title: Configure NFS Export with Autofs Client
# Category: networking
# Target: node1

check '[[ -d /users ]]' \
    "Directory /users exists" \
    "Directory /users does not exist"

check '[[ -d /users/linda ]]' \
    "Directory /users/linda exists" \
    "Directory /users/linda does not exist"

check '[[ -d /users/anna ]]' \
    "Directory /users/anna exists" \
    "Directory /users/anna does not exist"

check 'systemctl is-active nfs-server &>/dev/null' \
    "NFS server is running" \
    "NFS server is not running"

check 'grep -qE "^/users[[:space:]]" /etc/exports' \
    "/users is in /etc/exports" \
    "/users is not in /etc/exports"

check 'exportfs -v 2>/dev/null | grep -q "/users"' \
    "/users is actively exported" \
    "/users is not actively exported"
