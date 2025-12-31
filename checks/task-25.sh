#!/usr/bin/env bash
# Task: Create user50 with non-interactive shell

check 'id user50 &>/dev/null' \
    "User user50 exists" \
    "User user50 does not exist"

check 'getent passwd user50 | grep -qE "nologin|/bin/false"' \
    "User user50 has non-interactive shell" \
    "User user50 has interactive shell"
