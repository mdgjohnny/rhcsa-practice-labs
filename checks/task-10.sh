#!/usr/bin/env bash
# Task: Configure the system password policy so that passwords for newly created users expire after 90 days.
# Title: Set Password Aging Policy
# Category: users-groups
# Target: node1

check 'grep -E "^PASS_MAX_DAYS[[:space:]]+90" /etc/login.defs &>/dev/null' \
    "Password maximum age set to 90 days" \
    "Password maximum age not configured correctly"
