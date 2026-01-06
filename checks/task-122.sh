#!/usr/bin/env bash
# Task: Create a group sysadmins. Make users linda and anna members of this group and ensure that all members of this group can run all administrative commands using sudo
# Category: users-groups
# Target: node1


check \'run_ssh "$NODE1_IP" "id linda" &>/dev/null\' \
    "User linda exists" \
    "User linda does not exist"
check \'run_ssh "$NODE1_IP" "getent group sysadmins" &>/dev/null\' \
    "Group sysadmins exists" \
    "Group sysadmins does not exist"
check \'run_ssh "$NODE1_IP" "getent group and" &>/dev/null\' \
    "Group and exists" \
    "Group and does not exist"
check \'run_ssh "$NODE1_IP" "getent group can" &>/dev/null\' \
    "Group can exists" \
    "Group can does not exist"
