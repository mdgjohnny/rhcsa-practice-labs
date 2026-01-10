#!/usr/bin/env bash
# Task: As user20: Launch a ubi9 container with SHELL and HOSTNAME environment variables set. Enable linger for user20 for auto-start capability. The container should persist across reboots.
# Title: Container with Environment Variables
# Category: containers
# Target: node1
# Auto-start via systemd without login

check 'su - user20 -c "podman ps -a 2>/dev/null | grep -qi ubi9"' \
    "user20 has ubi9 container" \
    "user20 does not have ubi9 container"

check 'loginctl show-user user20 2>/dev/null | grep -q "Linger=yes"' \
    "Linger enabled for user20" \
    "Linger not enabled for user20"
