#!/usr/bin/env bash
# Task: Launch a container as user20 using the latest version of ubi8 image. Configure the container to auto-start at system reboots without the need for user20 to log in
# Category: operate-systems
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
