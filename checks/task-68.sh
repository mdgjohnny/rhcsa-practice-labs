#!/usr/bin/env bash
# Task: As user20: Pull and run a container using the ubi8 image. Configure it as a systemd user service with auto-start. Enable linger for user20 so the container starts at boot without requiring login. Verify: loginctl show-user user20 | grep Linger
# Title: Launch ubi8 Container (user20)
# Category: containers
# Target: node1
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
