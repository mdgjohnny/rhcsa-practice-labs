#!/usr/bin/env bash
# Task: Use podman to export a container's filesystem to /root/container-export.tar.
# Title: Export Container Filesystem
# Category: containers
# Target: node1
# Setup: podman run -d --name exportme ubi8 sleep 3600

check '[[ -f /root/container-export.tar ]]' \
    "Export file exists" \
    "Export file not found"

check 'tar tf /root/container-export.tar 2>/dev/null | grep -q "etc\|usr"' \
    "Export contains filesystem" \
    "Export doesn't contain expected filesystem"
