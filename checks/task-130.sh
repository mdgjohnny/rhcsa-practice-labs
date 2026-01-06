#!/usr/bin/env bash
# Task: Set password policy: 3 day warning before expiry, 120 day maximum lifetime
# Category: users-groups
# Target: node1


check 'id should &>/dev/null' \
    "User should exists" \
    "User should does not exist"
# Check /etc/login.defs for password policies
check 'grep -q "PASS_MAX_DAYS.*120" /etc/login.defs' \
    "PASS_MAX_DAYS is set to 120" \
    "PASS_MAX_DAYS is not 120"
