#!/usr/bin/env bash
# Task: Create a rootful (root-owned) container with port 443 mapped to the host. Configure it as a systemd service for automatic startup at boot.
# Title: Rootful Container with Port 443
# Category: containers
# Target: node2

check 'podman ps -a 2>/dev/null | grep -q 443' \
    "Container with port 443 exists" \
    "No container with port 443"

check 'systemctl list-units --type=service | grep -qi container' \
    "Container systemd service exists" \
    "No container systemd service"
