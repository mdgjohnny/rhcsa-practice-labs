#!/usr/bin/env bash
# Task: Create a directory with the name /users and ensure it contains the subdirectories linda and anna. Export this directory by using an NFS server
# Category: networking
# Target: node1

# Check directory structure exists
check \'run_ssh "$NODE1_IP" "test -d /users"\' \
    "Directory /users exists" \
    "Directory /users does not exist"

check \'run_ssh "$NODE1_IP" "test -d /users/linda"\' \
    "Directory /users/linda exists" \
    "Directory /users/linda does not exist"

check \'run_ssh "$NODE1_IP" "test -d /users/anna"\' \
    "Directory /users/anna exists" \
    "Directory /users/anna does not exist"

# Check NFS server is running
check \'run_ssh "$NODE1_IP" "systemctl is-active nfs-server &>/dev/null"\' \
    "NFS server is running" \
    "NFS server is not running"

# Check /users is exported
check \'run_ssh "$NODE1_IP" "grep -q "^/users" /etc/exports"\' \
    "/users is in /etc/exports" \
    "/users is not in /etc/exports"

# Check export is active
check 'exportfs -v 2>/dev/null | grep -q "/users"' \
    "/users is actively exported" \
    "/users is not actively exported"
