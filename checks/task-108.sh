#!/usr/bin/env bash
# Task: Create users laura and linda and make them members of the group livingopensource as a secondary group membership. Also, create users lisa and lori and make them members of the group operations as a secondary group
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
