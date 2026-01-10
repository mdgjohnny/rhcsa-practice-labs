#!/usr/bin/env bash
# Task: As user20: Launch ubi9 container with SHELL and HOSTNAME environment variables. Configure as systemd user service for auto-start at boot.
# Title: Container with Systemd Service
# Category: containers
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
