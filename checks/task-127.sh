#!/usr/bin/env bash
# Task: Create MariaDB container exposed on port 3306 with /var/mariadb-container as bind mount.
# Title: Deploy MariaDB Container
# Category: containers
# Target: node1


check '[[ -d /var/mariadb ]]' \
    "Directory /var/mariadb exists" \
    "Directory /var/mariadb does not exist"
check 'systemctl is-active mariadb &>/dev/null' \
    "Service mariadb is running" \
    "Service mariadb is not running"
check 'systemctl is-enabled mariadb &>/dev/null' \
    "Service mariadb is enabled" \
    "Service mariadb is not enabled"
check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
check 'ss -tlnp | grep -q ":3306"' \
    "Port 3306 is listening" \
    "Port 3306 is not listening"
