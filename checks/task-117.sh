#!/usr/bin/env bash
# Task: Create users linda and anna and make them members of the group sales as a secondary group membership. Also, create users serene and alex and make them members of the group account as a secondary group
# Category: users-groups
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
check 'id serene &>/dev/null' \
    "User serene exists" \
    "User serene does not exist"
check 'getent group sales &>/dev/null' \
    "Group sales exists" \
    "Group sales does not exist"
check 'getent group account &>/dev/null' \
    "Group account exists" \
    "Group account does not exist"
