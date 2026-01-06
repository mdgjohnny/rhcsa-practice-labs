#!/usr/bin/env bash
# Task: Create user student with password password, and user root with password password
# Category: users-groups
# Target: node1


check \'run_ssh "$NODE1_IP" "id student" &>/dev/null\' \
    "User student exists" \
    "User student does not exist"
check \'run_ssh "$NODE1_IP" "id root" &>/dev/null\' \
    "User root exists" \
    "User root does not exist"
check \'run_ssh "$NODE1_IP" "id root" &>/dev/null\' \
    "User root exists" \
    "User root does not exist"
