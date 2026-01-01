#!/usr/bin/env bash
# Task: All user passwords should expire after 90 days and be at least 9
# Category: users-groups
# characters in length


check ' [[ grep PASS_MAX_DAYS.*90 /etc/login.defs &>/dev/null ]] ' \
    "Password validity is set to 90 days" \
    "Password validity is not set to 90 days"
