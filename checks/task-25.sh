#!/usr/bin/env bash
# Task: Create user "user50" with a non-interactive shell (/sbin/nologin or similar).
# Title: Create Non-interactive User
# Category: users-groups

check 'id user50 &>/dev/null' \
    "User user50 exists" \
    "User user50 does not exist"

check 'getent passwd user50 | grep -qE "nologin|/bin/false"' \
    "User user50 has non-interactive shell" \
    "User user50 has interactive shell"
