#!/usr/bin/env bash
# Task: Configure MySQL container from docker.io/library/mysql:latest
# Category: containers
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
