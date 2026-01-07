#!/usr/bin/env bash
# Task: Configure container from task-102 as a systemd user service
# Title: Container Systemd Service
# Category: operate-systems
# Target: node1


check 'id service &>/dev/null' \
    "User service exists" \
    "User service does not exist"
check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
