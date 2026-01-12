#!/usr/bin/env bash
# Task: Create users linda and anna. Configure autofs to auto-mount their home directories via NFS.
# Title: Configure Autofs for NFS Home Directories
# Category: users-groups
# Target: node1

check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"

check 'id anna &>/dev/null' \
    "User anna exists" \
    "User anna does not exist"

check 'systemctl is-active autofs &>/dev/null' \
    "Autofs service is running" \
    "Autofs service is not running"

check 'grep -rq "linda\|anna\|/home" /etc/auto.* 2>/dev/null' \
    "Autofs has home directory configuration" \
    "Autofs not configured for home directories"
