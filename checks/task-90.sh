#!/usr/bin/env bash
# Task: Create users "student" and "root" with password "password".
# Title: Create System Users
# Category: users-groups
# Target: node1


check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"
check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
