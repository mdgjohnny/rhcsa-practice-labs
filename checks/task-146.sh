#!/usr/bin/env bash
# Task: Create user "user40" with UID 2929 and password "user1234".
# Title: Create User with Specific UID
# Category: users-groups
# Target: node1


check 'id user40 &>/dev/null' \
    "User user40 exists" \
    "User user40 does not exist"
check '[[ $(id -u user40 2>/dev/null) == "2929" ]]' \
    "User user40 has UID 2929" \
    "User user40 does not have UID 2929"
