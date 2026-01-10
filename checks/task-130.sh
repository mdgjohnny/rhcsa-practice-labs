#!/usr/bin/env bash
# Task: Set password policy: 3 day warning before expiry and 120 day maximum password lifetime.
# Title: Configure Password Aging
# Category: users-groups
# Target: node1


# Check /etc/login.defs for password policies
check 'grep -qE "^PASS_WARN_AGE[[:space:]]+3" /etc/login.defs' \
    "PASS_WARN_AGE is set to 3" \
    "PASS_WARN_AGE is not 3"

check 'grep -qE "^PASS_MAX_DAYS[[:space:]]+120" /etc/login.defs' \
    "PASS_MAX_DAYS is set to 120" \
    "PASS_MAX_DAYS is not 120"
