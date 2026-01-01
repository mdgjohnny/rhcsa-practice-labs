#!/usr/bin/env bash
# Task: On rhcsa2 - Mariadb container as user edwin
# Category: containers
# Port 3306, /var/mariadb-container for persistent storage

check 'run_ssh "$NODE2_IP" "id edwin &>/dev/null"' \
    "User edwin exists on node2" \
    "User edwin does not exist"

check 'run_ssh "$NODE2_IP" "[[ -d /var/mariadb-container ]]"' \
    "/var/mariadb-container exists on node2" \
    "/var/mariadb-container does not exist"

check 'run_ssh "$NODE2_IP" "loginctl show-user edwin 2>/dev/null | grep -q Linger=yes"' \
    "Linger enabled for edwin on node2" \
    "Linger not enabled for edwin"

check 'run_ssh "$NODE2_IP" "su - edwin -c \"podman ps -a 2>/dev/null | grep -qi mariadb\""' \
    "edwin has mariadb container on node2" \
    "edwin does not have mariadb container"
