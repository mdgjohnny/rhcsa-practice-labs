#!/usr/bin/env bash
# Task: Create group10 with user20 and user30 as secondary members
# Category: users-groups

check 'getent group group10 &>/dev/null' \
    "Group group10 exists" \
    "Group group10 does not exist"

check 'id -nG user20 | grep -q group10' \
    "User user20 is member of group10" \
    "User user20 is not member of group10"

check 'id -nG user30 | grep -q group10' \
    "User user30 is member of group10" \
    "User user30 is not member of group10"
