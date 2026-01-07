#!/usr/bin/env bash
# Task: Create user vicky with the custom UID 2008
# Title: Create User with Custom UID
# Category: users-groups
# Target: node1


check 'id vicky &>/dev/null' \
    "User vicky exists" \
    "User vicky does not exist"
check 'id vicky &>/dev/null' \
    "User vicky exists" \
    "User vicky does not exist"
check '[[ $(id -u vicky 2>/dev/null) == "2008" ]]' \
    "User vicky has UID 2008" \
    "User vicky does not have UID 2008"
