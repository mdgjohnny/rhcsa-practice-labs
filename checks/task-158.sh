#!/usr/bin/env bash
# Task: As user20, launch ubi9 container with SHELL and HOSTNAME env vars. Configure systemd auto-start.
# Title: Container with Env Variables
# Category: containers
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
