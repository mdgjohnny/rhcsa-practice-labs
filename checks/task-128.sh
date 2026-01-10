#!/usr/bin/env bash
# Task: The "student" user is pre-created. Configure a MariaDB container to run as a systemd user service for this user. The container should be running when graded.
# Title: MariaDB Container User Service
# Category: containers
# Target: node1


check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"
check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
