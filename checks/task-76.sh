#!/usr/bin/env bash
# Task: For user edwin (from task-75): Configure the MariaDB container as a systemd user service. Create ~/.config/systemd/user/ directory and place the service file there. Enable the service.
# Title: MariaDB Systemd User Service
# Category: containers
# Target: node2

check '[[ -d /home/edwin/.config/systemd/user ]]' \
    "Systemd user directory exists for edwin" \
    "Systemd user directory does not exist"

check 'ls /home/edwin/.config/systemd/user/*.service 2>/dev/null | grep -qi container' \
    "Container service file exists for edwin" \
    "Container service file does not exist"
