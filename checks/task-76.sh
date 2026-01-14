#!/usr/bin/env bash
# Task: As user edwin, create a systemd user service to manage a container. The service file should be in ~/.config/systemd/user/. Enable and start the service. Enable linger for edwin so the service runs without login.
# Title: Container as Systemd User Service
# Category: containers
# Target: node2

check '[[ -d /home/edwin/.config/systemd/user ]]' \
    "Systemd user directory exists for edwin" \
    "Systemd user directory does not exist"

check 'ls /home/edwin/.config/systemd/user/*.service 2>/dev/null | wc -l | grep -qE "[1-9]"' \
    "Service file exists in user systemd directory" \
    "No service file found"

check 'loginctl show-user edwin 2>/dev/null | grep -q "Linger=yes" || [[ -f /var/lib/systemd/linger/edwin ]]' \
    "Linger is enabled for edwin" \
    "Linger not enabled for edwin"

check 'su - edwin -c "systemctl --user list-unit-files" 2>/dev/null | grep -qE "container.*enabled"' \
    "Container service is enabled" \
    "Container service not enabled"
