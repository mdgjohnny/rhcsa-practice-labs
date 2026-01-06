#!/usr/bin/env bash
# Task: Create a user account called user40 with UID 2929. Set the password to user1234
# Category: users-groups
# Target: node1


check \'run_ssh "$NODE1_IP" "id account" &>/dev/null\' \
    "User account exists" \
    "User account does not exist"
check '[[ $(id -u account 2>/dev/null) == "2929" ]]' \
    "User account has UID 2929" \
    "User account does not have UID 2929"
