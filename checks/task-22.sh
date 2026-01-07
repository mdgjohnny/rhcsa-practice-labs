#!/usr/bin/env bash
# Task: NFS export homes for user100/200/300, auto-mount under /home1 on rhcsa1
# Title: NFS Autofs Home Directories
# Category: file-systems

check 'id user100 &>/dev/null' \
    "User user100 exists" \
    "User user100 does not exist"

check 'id user200 &>/dev/null' \
    "User user200 exists" \
    "User user200 does not exist"

check 'id user300 &>/dev/null' \
    "User user300 exists" \
    "User user300 does not exist"

check '[[ -d /home1 ]]' \
    "Directory /home1 exists" \
    "Directory /home1 does not exist"

check 'grep -q "/home1" /etc/auto.master 2>/dev/null || grep -qr "/home1" /etc/auto.master.d/ 2>/dev/null' \
    "Autofs configured for /home1" \
    "Autofs not configured for /home1"

check 'systemctl is-active autofs &>/dev/null' \
    "Autofs service is running" \
    "Autofs service is not running"
