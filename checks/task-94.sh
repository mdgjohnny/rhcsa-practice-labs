#!/usr/bin/env bash
# Task: Create edwin/santos in livingopensource, serene/alex in operations; santos UID 1234 no shell
# Category: users-groups
# Target: node1


check 'id edwin &>/dev/null' \
    "User edwin exists" \
    "User edwin does not exist"
check 'id serene &>/dev/null' \
    "User serene exists" \
    "User serene does not exist"
check 'id santos &>/dev/null' \
    "User santos exists" \
    "User santos does not exist"
check '[[ $(id -u santos 2>/dev/null) == "1234" ]]' \
    "User santos has UID 1234" \
    "User santos does not have UID 1234"
check 'getent group livingopensource &>/dev/null' \
    "Group livingopensource exists" \
    "Group livingopensource does not exist"
check 'getent group operations &>/dev/null' \
    "Group operations exists" \
    "Group operations does not exist"
check 'getent group ensure &>/dev/null' \
    "Group ensure exists" \
    "Group ensure does not exist"
