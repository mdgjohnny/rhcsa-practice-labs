#!/usr/bin/env bash
# Task: Configure password aging: maximum 90 days validity. Apply to /etc/login.defs for new users.
# Title: Set Password Aging Policy
# Category: users-groups


check 'grep -E "^PASS_MAX_DAYS[[:space:]]+90" /etc/login.defs &>/dev/null' \
    "Password validity is set to 90 days" \
    "Password validity is not set to 90 days"
