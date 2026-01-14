#!/usr/bin/env bash
# Task: Create user santos if needed. Create /home/santos/mysql directory for data persistence. As santos, run a MySQL container with MYSQL_ROOT_PASSWORD=password and the mysql directory mounted for data persistence. Configure it to start automatically at system boot.
# Title: MySQL Container with Persistent Storage
# Category: containers
# Target: node2

check 'id santos &>/dev/null' \
    "User santos exists" \
    "User santos does not exist"

check '[[ -d /home/santos/mysql ]]' \
    "MySQL data directory exists" \
    "/home/santos/mysql does not exist"

check 'su - santos -c "podman ps -a 2>/dev/null" | grep -qi mysql' \
    "santos has MySQL container" \
    "santos does not have MySQL container"

check 'ls /home/santos/.config/systemd/user/*.service &>/dev/null' \
    "Container has systemd user service" \
    "No systemd service for container"

check 'loginctl show-user santos 2>/dev/null | grep -q "Linger=yes"' \
    "Container will start at boot" \
    "Container will not auto-start at boot"
