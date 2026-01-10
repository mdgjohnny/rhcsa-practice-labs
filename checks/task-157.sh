#!/usr/bin/env bash
# Task: As user20, launch ubi8 container configured to auto-start at boot without requiring login.
# Title: Container Auto-start
# Category: operate-systems
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
