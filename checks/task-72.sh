#!/usr/bin/env bash
# Task: Create user80 if needed. Create directory /data01. As user80, launch a rootless container with /data01 bind mount. Enable linger for auto-start without login.
# Title: Rootless Container Service (user80)
# Category: containers
# Target: node2

check 'id user80 &>/dev/null' \
    "User user80 exists" \
    "User user80 does not exist"

check '[[ -d /data01 ]]' \
    "/data01 exists" \
    "/data01 does not exist"

check 'loginctl show-user user80 2>/dev/null | grep -q Linger=yes' \
    "Linger enabled for user80" \
    "Linger not enabled for user80"
