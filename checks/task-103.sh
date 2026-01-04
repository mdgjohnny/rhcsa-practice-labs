#!/usr/bin/env bash
# Task: Configure this container such that it is automatically started on system boot as a system user service
# Category: operate-systems
# Target: node1


check 'id service &>/dev/null' \
    "User service exists" \
    "User service does not exist"
check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
