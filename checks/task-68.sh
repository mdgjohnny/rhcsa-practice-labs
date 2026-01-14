#!/usr/bin/env bash
# Task: As user20: Pull and run a rootless container using the ubi8 image. Configure it to start automatically at system boot, even when user20 is not logged in.
# Title: Configure Persistent Rootless Container
# Category: containers
# Target: node1

check 'su - user20 -c "podman ps -a 2>/dev/null | grep -qi ubi8"' \
    "user20 has ubi8 container" \
    "user20 does not have ubi8 container"

check 'ls /home/user20/.config/systemd/user/*.service &>/dev/null' \
    "Container configured as systemd user service" \
    "Container not configured as systemd service"

check 'loginctl show-user user20 2>/dev/null | grep -q "Linger=yes"' \
    "Container will start at boot without login" \
    "Container will not auto-start at boot"
