#!/usr/bin/env bash
# Task: Inspect a running container and find its IP address. Save it to /root/container-ip.txt.
# Title: Inspect Running Container Network
# Category: containers
# Target: node1
# Setup: podman run -d --name testcontainer ubi8 sleep 3600

check '[[ -f /root/container-ip.txt ]]' \
    "File /root/container-ip.txt exists" \
    "File not found"

check 'grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" /root/container-ip.txt' \
    "File contains valid IP address" \
    "No valid IP found"
