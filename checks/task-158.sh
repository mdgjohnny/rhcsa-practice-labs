#!/usr/bin/env bash
# Task: Launch ubi9 container as user20 with SHELL and HOSTNAME env vars, auto-start via systemd
# Title: Container with Env Variables
# Category: containers
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
