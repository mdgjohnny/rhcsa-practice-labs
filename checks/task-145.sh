#!/usr/bin/env bash
# Task: Create a group called group10 and add user20 and user30 as secondary members
# Category: users-groups
# Target: node1


check 'getent group group10 &>/dev/null' \
    "Group group10 exists" \
    "Group group10 does not exist"
