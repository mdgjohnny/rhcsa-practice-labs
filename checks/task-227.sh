#!/usr/bin/env bash
# Task: Pull the httpd image from docker.io/library/httpd:latest. Then run a container from it named "web01" in detached mode, mapping host port 8080 to container port 80.
# Title: Pull and Run HTTP Container
# Category: containers
# Target: node1

check 'podman images | grep -qE "docker.io.*httpd|httpd.*latest"' \
    "httpd image is pulled" \
    "httpd image not found"

check 'podman ps --format "{{.Names}}" | grep -q "^web01$"' \
    "Container web01 is running" \
    "Container web01 not running"

check 'podman port web01 2>/dev/null | grep -q "8080->80"' \
    "Port 8080 mapped to container port 80" \
    "Port mapping not correct"
