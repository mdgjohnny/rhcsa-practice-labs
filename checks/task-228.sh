#!/usr/bin/env bash
# Task: Pull the nginx:alpine image from Docker Hub. Run a container named "nginx-test" from it that mounts /var/www/html from the host to /usr/share/nginx/html in the container. The container should run in detached mode.
# Title: Run Container with Bind Mount
# Category: containers
# Target: node1

check 'podman images | grep -qE "nginx.*alpine"' \
    "nginx:alpine image is pulled" \
    "nginx:alpine image not found"

check 'podman ps --format "{{.Names}}" | grep -q "^nginx-test$"' \
    "Container nginx-test is running" \
    "Container nginx-test not running"

check 'podman inspect nginx-test 2>/dev/null | grep -q "/var/www/html"' \
    "Container has /var/www/html mount" \
    "Bind mount not configured correctly"
