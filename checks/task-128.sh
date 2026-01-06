#!/usr/bin/env bash
# Task: Configure your system such that the container created in step 15 is automatically started as a Systemd user container
# Category: containers
# Target: node1


check \'run_ssh "$NODE1_IP" "id container" &>/dev/null\' \
    "User container exists" \
    "User container does not exist"
check \'run_ssh "$NODE1_IP" "podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q ."\' \
    "Container is running" \
    "No container is running"
