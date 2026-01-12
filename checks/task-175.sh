#!/usr/bin/env bash
# Task: Pull the ubi8 image and use podman inspect to find its default command (Cmd). Create a file /root/container-cmd.txt containing only that command.
# Title: Inspect Container Image
# Category: containers
# Target: node1

check 'podman image exists registry.access.redhat.com/ubi8/ubi 2>/dev/null || podman image exists ubi8 2>/dev/null' \
    "UBI8 image is present" \
    "UBI8 image not found (pull it first)"

check '[[ -f /root/container-cmd.txt ]]' \
    "File /root/container-cmd.txt exists" \
    "File /root/container-cmd.txt not found"

check 'grep -qiE "bash|sh|/bin" /root/container-cmd.txt' \
    "File contains the container command" \
    "File doesn't contain expected command"
