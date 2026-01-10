#!/usr/bin/env bash
# Task: Create users linda and anna with home directories auto-mounted via NFS under /home/users using autofs.
# Title: Configure Autofs for NFS Home Directories
# Category: users-groups
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
check 'id access &>/dev/null' \
    "User access exists" \
    "User access does not exist"
check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"
check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
check 'systemctl is-active autofs &>/dev/null' \
    "Service autofs is running" \
    "Service autofs is not running"
