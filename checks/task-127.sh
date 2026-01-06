#!/usr/bin/env bash
# Task: Configure your system to automatically start a mariadb container. This container should expose its services at port 3306 and use the directory /var/mariadb-container on the host for persistent storage of files it writes to the /var directory
# Category: containers
# Target: node1


check \'run_ssh "$NODE1_IP" "test -d /var/mariadb"\' \
    "Directory /var/mariadb exists" \
    "Directory /var/mariadb does not exist"
check \'run_ssh "$NODE1_IP" "systemctl is-active mariadb &>/dev/null"\' \
    "Service mariadb is running" \
    "Service mariadb is not running"
check \'run_ssh "$NODE1_IP" "systemctl is-enabled mariadb &>/dev/null"\' \
    "Service mariadb is enabled" \
    "Service mariadb is not enabled"
check \'run_ssh "$NODE1_IP" "podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q ."\' \
    "Container is running" \
    "No container is running"
check 'ss -tlnp | grep -q ":3306"' \
    "Port 3306 is listening" \
    "Port 3306 is not listening"
