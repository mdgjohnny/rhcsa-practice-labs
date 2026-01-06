#!/usr/bin/env bash
# Task: Launch rootless container as user100 with /data01 mount
# Category: containers
# KERN and SHELL variables, auto-start via systemd

check \'run_ssh "$NODE1_IP" "id user100" &>/dev/null\' \
    "User user100 exists" \
    "User user100 does not exist"

check \'run_ssh "$NODE1_IP" "test -d /data01"\' \
    "Directory /data01 exists" \
    "Directory /data01 does not exist"

check \'run_ssh "$NODE1_IP" "loginctl show-user user100 2>/dev/null | grep -q "Linger=yes""\' \
    "Linger enabled for user100" \
    "Linger not enabled for user100"
