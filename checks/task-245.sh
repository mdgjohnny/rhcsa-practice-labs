#!/usr/bin/env bash
# Task: Run a container with /host/data from the host mapped to /data in the container with read-only access.
# Title: Container with Read-Only Bind Mount
# Category: containers
# Target: node1
# Setup: mkdir -p /host/data; echo "testfile" > /host/data/test.txt

check 'podman ps -a --format "{{.Mounts}}" | grep -qE "/host/data.*ro|:ro"' \
    "Container has read-only mount" \
    "No read-only mount found"
