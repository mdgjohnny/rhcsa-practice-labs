#!/usr/bin/env bash
# Task: As user20: Configure a ubi8 container to auto-start at boot without requiring user login. Use systemd user services and enable linger.
# Title: Container Auto-start (user20)
# Category: operate-systems
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
