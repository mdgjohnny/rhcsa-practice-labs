#!/usr/bin/env bash
# Task: Launch ubi8 container as user20 with auto-start at boot (no login required)
# Title: Container Auto-start (user20)
# Category: operate-systems
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
