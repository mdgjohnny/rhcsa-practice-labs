#!/usr/bin/env bash
# Task: On rhcsa2 - MySQL container as rootless (user santos)
# Category: containers
# Password "password", bind mount /home/santos/mysql to /var/lib/mysql
# Auto-start via systemd

check 'run_ssh "$NODE2_IP" "id santos &>/dev/null"' \
    "User santos exists on node2" \
    "User santos does not exist"

check 'run_ssh "$NODE2_IP" "[[ -d /home/santos/mysql ]]"' \
    "/home/santos/mysql exists on node2" \
    "/home/santos/mysql does not exist"

check 'run_ssh "$NODE2_IP" "loginctl show-user santos 2>/dev/null | grep -q Linger=yes"' \
    "Linger enabled for santos on node2" \
    "Linger not enabled for santos"

check 'run_ssh "$NODE2_IP" "su - santos -c \"podman ps -a 2>/dev/null | grep -qi mysql\""' \
    "santos has MySQL container on node2" \
    "santos does not have MySQL container"
