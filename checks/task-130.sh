#!/usr/bin/env bash
# Task: Set default values for new users. A user should get a warning three days before expiration of the current password. Also, new passwords should have a maximum lifetime of 120 days
# Category: users-groups
# Target: node1


check 'id should &>/dev/null' \
    "User should exists" \
    "User should does not exist"
# Check /etc/login.defs for password policies
check 'grep -q "PASS_MAX_DAYS.*120" /etc/login.defs' \
    "PASS_MAX_DAYS is set to 120" \
    "PASS_MAX_DAYS is not 120"
