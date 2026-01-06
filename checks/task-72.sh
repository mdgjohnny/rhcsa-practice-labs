#!/usr/bin/env bash
# Task: On rhcsa2 - Rootless container as user80 with /data01 mount
# Category: containers
# Auto-start via systemd

check 'run_ssh "$NODE2_IP" "id user80 &>/dev/null"' \
    "User user80 exists on node2" \
    "User user80 does not exist"

check 'run_ssh "$NODE2_IP" "[[ -d /data01 ]]"' \
    "/data01 exists on node2" \
    "/data01 does not exist on node2"

check 'run_ssh "$NODE2_IP" "loginctl show-user user80 2>/dev/null | grep -q Linger=yes"' \
    "Linger enabled for user80 on node2" \
    "Linger not enabled for user80"
