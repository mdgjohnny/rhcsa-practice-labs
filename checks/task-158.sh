#!/usr/bin/env bash
# Task: Launch a container as user20 using the latest version of ubi9 image with two environment variables SHELL and HOSTNAME Configure the container to auto-start via systemd without the need for user20 to log in. Connect to the container and verify variable settings password
# Category: containers
# Target: node1


check \'run_ssh "$NODE1_IP" "podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q ."\' \
    "Container is running" \
    "No container is running"
