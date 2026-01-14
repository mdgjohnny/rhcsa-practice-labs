#!/usr/bin/env bash
# Task: Pull the ubi8 container image and determine what command it runs by default when started. Save only the default command (not the full JSON) to /root/container-cmd.txt.
# Title: Discover Container Default Command
# Category: containers
# Target: node1

check 'podman images --format "{{.Repository}}" 2>/dev/null | grep -qiE "ubi8|ubi:8" || su - opc -c "podman images --format \"{{.Repository}}\"" 2>/dev/null | grep -qiE "ubi8|ubi:8"' \
    "UBI8 image is present" \
    "UBI8 image not found"

check '[[ -f /root/container-cmd.txt ]]' \
    "Output file exists" \
    "Output file /root/container-cmd.txt not found"

check 'grep -qiE "bash|sh|/bin" /root/container-cmd.txt' \
    "File contains the default command" \
    "File doesn't contain expected command"
