#!/usr/bin/env bash
# Task: As user20, launch a container using the ubi8 image.
# Title: Launch Container
# Category: containers
# Auto-start at boot without user login

check 'su - user20 -c "podman ps -a 2>/dev/null | grep -qi ubi8"' \
    "user20 has ubi8 container" \
    "user20 does not have ubi8 container"

check '[[ -f /home/user20/.config/systemd/user/*.service ]] || systemctl --user -M user20@ list-units --type=service | grep -q container' \
    "Systemd user service exists for container" \
    "No systemd user service for container"

check 'loginctl show-user user20 2>/dev/null | grep -q "Linger=yes"' \
    "Linger enabled for user20 (auto-start without login)" \
    "Linger not enabled for user20"
