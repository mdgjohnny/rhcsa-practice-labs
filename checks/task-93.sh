#!/usr/bin/env bash
# Task: Set default values for new users. Set the default password validity to 90 days, and set the first UID that is used for new users to 2000
# Category: users-groups
# Target: node1


# Check /etc/login.defs for password policies
check 'grep -q "PASS_MAX_DAYS.*90" /etc/login.defs' \
    "PASS_MAX_DAYS is set to 90" \
    "PASS_MAX_DAYS is not 90"
