#!/usr/bin/env bash
# Task: Create a container that uses tmpfs mount for /tmp with size limit of 100M.
# Title: Container with tmpfs Mount
# Category: containers
# Target: node1

check 'podman ps -a --format "{{.Mounts}}" | grep -qi "tmpfs"' \
    "Container has tmpfs mount" \
    "No tmpfs mount found"
