#!/usr/bin/env bash
# Task: Create user50 with non-interactive shell
# Category: users-groups

check \'run_ssh "$NODE1_IP" "id user50" &>/dev/null\' \
    "User user50 exists" \
    "User user50 does not exist"

check \'run_ssh "$NODE1_IP" "getent passwd user50" | grep -qE "nologin|/bin/false"\' \
    "User user50 has non-interactive shell" \
    "User user50 has interactive shell"
