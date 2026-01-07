#!/usr/bin/env bash
# Task: Configure mariadb container as systemd user service
# Title: Container Systemd User Service
# Category: containers
# Target: node1


check 'id container &>/dev/null' \
    "User container exists" \
    "User container does not exist"
check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
