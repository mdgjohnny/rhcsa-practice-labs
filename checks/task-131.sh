#!/usr/bin/env bash
# Task: Create users lori and laura and make them members of the secondary group sales. Ensure that user lori uses UID 2000 and user laura uses UID 2001
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
