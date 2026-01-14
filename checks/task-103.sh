#!/usr/bin/env bash
# Task: As user student, create a rootless httpd container and configure it as a systemd user service. Enable linger so the service starts at boot without login. The service should be enabled.
# Title: Rootless Container as Systemd User Service
# Category: containers
# Target: node1

check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"

check '[[ -d /home/student/.config/systemd/user ]]' \
    "User systemd directory exists" \
    "~/.config/systemd/user not found"

check 'ls /home/student/.config/systemd/user/*.service 2>/dev/null | wc -l | grep -qE "[1-9]"' \
    "Service unit file exists" \
    "No service unit file found"

check 'loginctl show-user student 2>/dev/null | grep -q "Linger=yes" || [[ -f /var/lib/systemd/linger/student ]]' \
    "Linger enabled for student" \
    "Linger not enabled"

check 'su - student -c "systemctl --user is-enabled container-*.service 2>/dev/null || systemctl --user list-unit-files 2>/dev/null | grep -E \"container.*enabled\"" 2>/dev/null | grep -qE "enabled"' \
    "Container service is enabled" \
    "Container service not enabled"
