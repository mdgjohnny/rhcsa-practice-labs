#!/usr/bin/env bash
# Task: Set default values for new users. Make sure that any new user password has a length of at least six characters and must be used for at least three days before it can be reset
# Category: users-groups
# Target: node1


check 'id password &>/dev/null' \
    "User password exists" \
    "User password does not exist"
# Check /etc/login.defs for password policies
