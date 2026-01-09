#!/usr/bin/env bash
# Task: Configure mariadb container from task-75 as systemd user container
# Title: Container Systemd Service
# Category: containers
# Target: node2

check '[[ -d /home/edwin/.config/systemd/user ]]' \
    "Systemd user directory exists for edwin" \
    "Systemd user directory does not exist"

check 'ls /home/edwin/.config/systemd/user/*.service 2>/dev/null | grep -qi container' \
    "Container service file exists for edwin" \
    "Container service file does not exist"
