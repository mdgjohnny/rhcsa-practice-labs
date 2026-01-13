#!/usr/bin/env bash
# Task: Pull the ubi8 image and use podman inspect to find its default command (Cmd). Create a file /root/container-cmd.txt containing only that command.
# Title: Inspect Container Image
# Category: containers
# Target: node1

# Accept various ubi8 image names/registries
check 'podman images --format "{{.Repository}}" 2>/dev/null | grep -qiE "ubi8|ubi:8"' \
    "UBI8 image is present" \
    "UBI8 image not found"

check '[[ -f /root/container-cmd.txt ]]' \
    "File /root/container-cmd.txt exists" \
    "File /root/container-cmd.txt not found"

check 'grep -qiE "bash|sh|/bin" /root/container-cmd.txt' \
    "File contains the container command" \
    "File doesn't contain expected command"
