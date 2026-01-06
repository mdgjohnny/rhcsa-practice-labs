#!/usr/bin/env bash
# Task: Create users laura/linda in group livingopensource, lisa/lori in group operations
# Category: users-groups
# Target: node1


check 'id laura &>/dev/null' \
    "User laura exists" \
    "User laura does not exist"
check 'id lisa &>/dev/null' \
    "User lisa exists" \
    "User lisa does not exist"
check 'getent group livingopensource &>/dev/null' \
    "Group livingopensource exists" \
    "Group livingopensource does not exist"
check 'getent group operations &>/dev/null' \
    "Group operations exists" \
    "Group operations does not exist"
