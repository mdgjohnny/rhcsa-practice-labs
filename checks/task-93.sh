#!/usr/bin/env bash
# Task: Configure password validity to 90 days and first UID for new users to 2000.
# Title: Set Password and UID Defaults
# Category: users-groups
# Target: node1


# Check /etc/login.defs for password policies
check 'grep -q "PASS_MAX_DAYS.*90" /etc/login.defs' \
    "PASS_MAX_DAYS is set to 90" \
    "PASS_MAX_DAYS is not 90"
