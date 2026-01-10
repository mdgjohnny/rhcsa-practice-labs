#!/usr/bin/env bash
# Task: Create user100 if needed. Create directory /data01. As user100, launch a rootless container with /data01 mounted inside. Enable linger for user100 to allow auto-start.
# Title: Rootless Container with Bind Mount
# Category: containers
# KERN and SHELL variables, auto-start via systemd

check 'id user100 &>/dev/null' \
    "User user100 exists" \
    "User user100 does not exist"

check '[[ -d /data01 ]]' \
    "Directory /data01 exists" \
    "Directory /data01 does not exist"

check 'loginctl show-user user100 2>/dev/null | grep -q "Linger=yes"' \
    "Linger enabled for user100" \
    "Linger not enabled for user100"
