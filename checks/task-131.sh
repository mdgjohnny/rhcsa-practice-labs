#!/usr/bin/env bash
# Task: Create users lori (UID 2000) and laura (UID 2001) in sales group
# Category: users-groups
# Target: node1


check 'id lori &>/dev/null' \
    "User lori exists" \
    "User lori does not exist"
check 'id lori &>/dev/null' \
    "User lori exists" \
    "User lori does not exist"
check 'id laura &>/dev/null' \
    "User laura exists" \
    "User laura does not exist"
check '[[ $(id -u lori 2>/dev/null) == "2000" ]]' \
    "User lori has UID 2000" \
    "User lori does not have UID 2000"
check 'getent group sales &>/dev/null' \
    "Group sales exists" \
    "Group sales does not exist"
