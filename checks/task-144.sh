#!/usr/bin/env bash
# Task: Create user accounts called user10, user20, and user30. Set their passwords to Temp1234. Make user10 and user30 accounts to expire on December 31, 2023
# Category: users-groups
# Target: node1

# Check users exist
check \'run_ssh "$NODE1_IP" "id user10" &>/dev/null\' \
    "User user10 exists" \
    "User user10 does not exist"

check \'run_ssh "$NODE1_IP" "id user20" &>/dev/null\' \
    "User user20 exists" \
    "User user20 does not exist"

check \'run_ssh "$NODE1_IP" "id user30" &>/dev/null\' \
    "User user30 exists" \
    "User user30 does not exist"

# Check expiry for user10
check \'run_ssh "$NODE1_IP" "chage -l user10 2>/dev/null | grep -q "Dec 31, 2023\|2023-12-31""\' \
    "User user10 expires Dec 31, 2023" \
    "User user10 expiry not set correctly"

# Check expiry for user30
check \'run_ssh "$NODE1_IP" "chage -l user30 2>/dev/null | grep -q "Dec 31, 2023\|2023-12-31""\' \
    "User user30 expires Dec 31, 2023" \
    "User user30 expiry not set correctly"
