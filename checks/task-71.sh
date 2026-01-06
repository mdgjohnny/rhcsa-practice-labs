#!/usr/bin/env bash
# Task: On rhcsa2 - Rootful container with port 443 mapped
# Category: containers
# Auto-start via systemd

check 'run_ssh "$NODE2_IP" "podman ps -a 2>/dev/null | grep -q 443"' \
    "Container with port 443 exists on node2" \
    "No container with port 443 on node2"

check 'run_ssh "$NODE2_IP" "systemctl list-units --type=service | grep -qi container"' \
    "Container systemd service exists on node2" \
    "No container systemd service on node2"
