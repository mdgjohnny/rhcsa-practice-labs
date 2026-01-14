#!/usr/bin/env bash
# Task: Create user80 if needed. Create directory /data01. As user80, launch a rootless container with /data01 bind-mounted inside. Configure it to start automatically at system boot without requiring user80 to log in.
# Title: Rootless Container Service (user80)
# Category: containers
# Target: node2

check 'id user80 &>/dev/null' \
    "User user80 exists" \
    "User user80 does not exist"

check '[[ -d /data01 ]]' \
    "/data01 exists" \
    "/data01 does not exist"

check 'su - user80 -c "podman ps -a" 2>/dev/null | grep -v "CONTAINER ID" | grep -q "."' \
    "user80 has a container" \
    "No container found for user80"

check 'ls /home/user80/.config/systemd/user/*.service &>/dev/null' \
    "Container has systemd user service" \
    "No systemd service for container"

check 'loginctl show-user user80 2>/dev/null | grep -q "Linger=yes"' \
    "Container will start at boot" \
    "Container will not auto-start at boot"
