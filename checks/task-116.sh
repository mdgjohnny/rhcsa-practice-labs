#!/usr/bin/env bash
# Task: Set password policy: minimum 6 characters, 3 day minimum age
# Title: Password Length & Age Policy
# Category: users-groups
# Target: node1


check 'id password &>/dev/null' \
    "User password exists" \
    "User password does not exist"
# Check /etc/login.defs for password policies
