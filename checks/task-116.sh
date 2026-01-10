#!/usr/bin/env bash
# Task: Set password policy: minimum 6 characters length and 3 day minimum age between password changes.
# Title: Set Password Complexity Policy
# Category: users-groups
# Target: node1

check 'grep -E "^PASS_MIN_LEN[[:space:]]+[6-9]|^PASS_MIN_LEN[[:space:]]+[0-9][0-9]" /etc/login.defs &>/dev/null' \
    "Minimum password length is 6 or more" \
    "Minimum password length not set to 6+"

check 'grep -E "^PASS_MIN_DAYS[[:space:]]+[3-9]|^PASS_MIN_DAYS[[:space:]]+[0-9][0-9]" /etc/login.defs &>/dev/null' \
    "Minimum password age is 3 days or more" \
    "Minimum password age not set to 3+ days"
