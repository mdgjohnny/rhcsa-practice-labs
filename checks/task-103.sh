#!/usr/bin/env bash
# Task: Configure this container such that it is automatically started on system boot as a system user service
# Category: operate-systems
# Target: node1


check \'run_ssh "$NODE1_IP" "id service" &>/dev/null\' \
    "User service exists" \
    "User service does not exist"
check \'run_ssh "$NODE1_IP" "podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q ."\' \
    "Container is running" \
    "No container is running"
