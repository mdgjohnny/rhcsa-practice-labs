#!/usr/bin/env bash
# Task: Create user100 if needed. Create directory /data01. As user100, launch a rootless container with /data01 mounted inside the container. Configure the container to start automatically at system boot, even when user100 is not logged in.
# Title: Rootless Container with Bind Mount
# Category: containers
# Target: node1

check 'id user100 &>/dev/null' \
    "User user100 exists" \
    "User user100 does not exist"

check '[[ -d /data01 ]]' \
    "Directory /data01 exists" \
    "Directory /data01 does not exist"

check 'su - user100 -c "podman ps -a" 2>/dev/null | grep -v "CONTAINER ID" | grep -q "."' \
    "user100 has a container" \
    "No container found for user100"

check 'ls /home/user100/.config/systemd/user/*.service &>/dev/null' \
    "Container has systemd user service" \
    "No systemd service for container"

check 'loginctl show-user user100 2>/dev/null | grep -q "Linger=yes"' \
    "Container will start at boot" \
    "Container will not auto-start at boot"
