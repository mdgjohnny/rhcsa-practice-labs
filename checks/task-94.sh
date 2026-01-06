#!/usr/bin/env bash
# Task: Create users edwin and santos and make them members of the group livingopensource as a secondary group membership. Also, create users serene and alex and make them members of the group operations as a secondary group Ensure that user santos has UID 1234 and cannot start an interactive shell
# Category: users-groups
# Target: node1


check \'run_ssh "$NODE1_IP" "id edwin" &>/dev/null\' \
    "User edwin exists" \
    "User edwin does not exist"
check \'run_ssh "$NODE1_IP" "id serene" &>/dev/null\' \
    "User serene exists" \
    "User serene does not exist"
check \'run_ssh "$NODE1_IP" "id santos" &>/dev/null\' \
    "User santos exists" \
    "User santos does not exist"
check '[[ $(id -u santos 2>/dev/null) == "1234" ]]' \
    "User santos has UID 1234" \
    "User santos does not have UID 1234"
check \'run_ssh "$NODE1_IP" "getent group livingopensource" &>/dev/null\' \
    "Group livingopensource exists" \
    "Group livingopensource does not exist"
check \'run_ssh "$NODE1_IP" "getent group operations" &>/dev/null\' \
    "Group operations exists" \
    "Group operations does not exist"
check \'run_ssh "$NODE1_IP" "getent group ensure" &>/dev/null\' \
    "Group ensure exists" \
    "Group ensure does not exist"
