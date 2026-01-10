#!/usr/bin/env bash
# Task: Create a user named "student". Configure the HTTP container (from task-102) as a systemd user service that starts automatically at boot.
# Title: HTTP Container Systemd Service
# Category: operate-systems
# Target: node1


check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"
check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
