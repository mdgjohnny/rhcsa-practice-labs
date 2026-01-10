#!/usr/bin/env bash
# Task: Set password policy: minimum 6 characters length and 3 day minimum age between password changes.
# Title: Set Password Complexity Policy
# Category: users-groups
# Target: node1


check 'id password &>/dev/null' \
    "User password exists" \
    "User password does not exist"
# Check /etc/login.defs for password policies
