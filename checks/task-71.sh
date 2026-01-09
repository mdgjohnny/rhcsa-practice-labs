#!/usr/bin/env bash
# Task: Rootful container with port 443 mapped, auto-start via systemd
# Title: Rootful Container (port 443)
# Category: containers
# Target: node2

check 'podman ps -a 2>/dev/null | grep -q 443' \
    "Container with port 443 exists" \
    "No container with port 443"

check 'systemctl list-units --type=service | grep -qi container' \
    "Container systemd service exists" \
    "No container systemd service"
