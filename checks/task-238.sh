#!/usr/bin/env bash
# Task: Run a container named "exportme" from the ubi8 image (with any command that keeps it running, like sleep). Then export its filesystem to /root/container-export.tar.
# Title: Export Container Filesystem
# Category: containers
# Target: node1

check 'podman ps -a --format "{{.Names}}" | grep -q "^exportme$"' \
    "Container exportme exists" \
    "Container exportme not found"

check '[[ -f /root/container-export.tar ]]' \
    "Export file exists" \
    "Export file not found"

check 'tar tf /root/container-export.tar 2>/dev/null | head -20 | grep -qE "^etc/|^usr/|^bin/"' \
    "Export contains filesystem structure" \
    "Export doesn't look like a filesystem"
