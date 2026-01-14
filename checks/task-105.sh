#!/usr/bin/env bash
# Task: On node2: Configure autofs to automatically mount user home directories from node1's /users export. Use indirect mapping so that accessing /remote/users/linda mounts node1:/users/linda, and /remote/users/anna mounts node1:/users/anna.
# Title: Configure Autofs for NFS Home Directories
# Category: file-systems
# Target: node2

check 'systemctl is-active autofs &>/dev/null' \
    "Autofs service is running" \
    "Autofs service is not running"

check 'grep -rqE "linda|anna|\*" /etc/auto.* 2>/dev/null' \
    "Autofs has user directory configuration" \
    "Autofs not configured for user directories"

check '[[ -d /remote/users ]] || grep -rq "/remote/users" /etc/auto.master 2>/dev/null' \
    "Mount point configured" \
    "Mount point /remote/users not configured"
