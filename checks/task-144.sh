#!/usr/bin/env bash
# Task: Create users user10/user20/user30 with password Temp1234, expire user10/user30 on Dec 31, 2023
# Title: Create Users with Expiry
# Category: users-groups
# Target: node1

# Check users exist
check 'id user10 &>/dev/null' \
    "User user10 exists" \
    "User user10 does not exist"

check 'id user20 &>/dev/null' \
    "User user20 exists" \
    "User user20 does not exist"

check 'id user30 &>/dev/null' \
    "User user30 exists" \
    "User user30 does not exist"

# Check expiry for user10
check 'chage -l user10 2>/dev/null | grep -q "Dec 31, 2023\|2023-12-31"' \
    "User user10 expires Dec 31, 2023" \
    "User user10 expiry not set correctly"

# Check expiry for user30
check 'chage -l user30 2>/dev/null | grep -q "Dec 31, 2023\|2023-12-31"' \
    "User user30 expires Dec 31, 2023" \
    "User user30 expiry not set correctly"
