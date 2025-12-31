#!/usr/bin/env bash
# Task: On rhcsa2 - Script to create user555, user666, user777
# No login shell, passwords matching usernames
# Extract usernames to /var/tmp/newusers

check 'ssh "$NODE2_IP" "id user555 &>/dev/null" 2>/dev/null' \
    "User user555 exists on node2" \
    "User user555 does not exist"

check 'ssh "$NODE2_IP" "id user666 &>/dev/null" 2>/dev/null' \
    "User user666 exists on node2" \
    "User user666 does not exist"

check 'ssh "$NODE2_IP" "id user777 &>/dev/null" 2>/dev/null' \
    "User user777 exists on node2" \
    "User user777 does not exist"

check 'ssh "$NODE2_IP" "getent passwd user555 | grep -qE \"nologin|/bin/false\"" 2>/dev/null' \
    "user555 has no login shell" \
    "user555 has login shell"

check 'ssh "$NODE2_IP" "[[ -f /var/tmp/newusers ]]" 2>/dev/null' \
    "/var/tmp/newusers exists on node2" \
    "/var/tmp/newusers does not exist"
