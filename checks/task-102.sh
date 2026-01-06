#!/usr/bin/env bash
# Task: Create a container that runs an HTTP server. Ensure that it mounts the host directory /httproot on the directory /var/www/html
# Category: containers
# Target: node1


check \'run_ssh "$NODE1_IP" "test -d /httproot"\' \
    "Directory /httproot exists" \
    "Directory /httproot does not exist"
check \'run_ssh "$NODE1_IP" "test -d /var/www/html"\' \
    "Directory /var/www/html exists" \
    "Directory /var/www/html does not exist"
check \'run_ssh "$NODE1_IP" "podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q ."\' \
    "Container is running" \
    "No container is running"
