#!/usr/bin/env bash
# Task: Create /users with linda and anna subdirectories, export via NFS
# Category: networking
# Target: node1

# Check directory structure exists
check '[[ -d /users ]]' \
    "Directory /users exists" \
    "Directory /users does not exist"

check '[[ -d /users/linda ]]' \
    "Directory /users/linda exists" \
    "Directory /users/linda does not exist"

check '[[ -d /users/anna ]]' \
    "Directory /users/anna exists" \
    "Directory /users/anna does not exist"

# Check NFS server is running
check 'systemctl is-active nfs-server &>/dev/null' \
    "NFS server is running" \
    "NFS server is not running"

# Check /users is exported
check 'grep -q "^/users" /etc/exports' \
    "/users is in /etc/exports" \
    "/users is not in /etc/exports"

# Check export is active
check 'exportfs -v 2>/dev/null | grep -q "/users"' \
    "/users is actively exported" \
    "/users is not actively exported"
