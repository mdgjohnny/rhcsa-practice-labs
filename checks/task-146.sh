#!/usr/bin/env bash
# Task: Create user user40 with UID 2929 and password user1234
# Title: Create User with UID
# Category: users-groups
# Target: node1


check 'id account &>/dev/null' \
    "User account exists" \
    "User account does not exist"
check '[[ $(id -u account 2>/dev/null) == "2929" ]]' \
    "User account has UID 2929" \
    "User account does not have UID 2929"
