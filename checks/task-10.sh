#!/usr/bin/env bash
# Task: Set password policy: expire after 90 days, minimum 9 characters
# Title: Password Expiry Policy
# Category: users-groups


check ' [[ grep PASS_MAX_DAYS.*90 /etc/login.defs &>/dev/null ]] ' \
    "Password validity is set to 90 days" \
    "Password validity is not set to 90 days"
