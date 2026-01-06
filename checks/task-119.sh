#!/usr/bin/env bash
# Task: User root is allowed to connect through SSH
# Category: networking
# Target: node1


check \'run_ssh "$NODE1_IP" "id root" &>/dev/null\' \
    "User root exists" \
    "User root does not exist"
