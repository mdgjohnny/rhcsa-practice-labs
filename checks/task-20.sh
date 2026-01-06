#!/usr/bin/env bash
# Task: Create user10, user20, user30 with password Temp1234. user10/user30 expire Dec 31, 2025
# Category: users-groups

check \'run_ssh "$NODE1_IP" "id user10" &>/dev/null\' \
    "User user10 exists" \
    "User user10 does not exist"

check \'run_ssh "$NODE1_IP" "id user20" &>/dev/null\' \
    "User user20 exists" \
    "User user20 does not exist"

check \'run_ssh "$NODE1_IP" "id user30" &>/dev/null\' \
    "User user30 exists" \
    "User user30 does not exist"

check \'run_ssh "$NODE1_IP" "chage -l user10 2>/dev/null | grep -q "Dec 31, 2025\|2025-12-31""\' \
    "User user10 expires on Dec 31, 2025" \
    "User user10 expiry not set correctly"

check \'run_ssh "$NODE1_IP" "chage -l user30 2>/dev/null | grep -q "Dec 31, 2025\|2025-12-31""\' \
    "User user30 expires on Dec 31, 2025" \
    "User user30 expiry not set correctly"
