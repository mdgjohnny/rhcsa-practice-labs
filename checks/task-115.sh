#!/usr/bin/env bash
# Task: Configure a container that runs the docker.io/library/mysql:latest image and ensure it meets the following conditions
# Category: containers
# Target: node1


check \'run_ssh "$NODE1_IP" "podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q ."\' \
    "Container is running" \
    "No container is running"
