#!/usr/bin/env bash
# Task: Create group "sysadmins" with members linda and anna. Grant the group full sudo access.
# Title: Configure Sudo Group
# Category: users-groups
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
check 'getent group sysadmins &>/dev/null' \
    "Group sysadmins exists" \
    "Group sysadmins does not exist"
check 'getent group and &>/dev/null' \
    "Group and exists" \
    "Group and does not exist"
check 'getent group can &>/dev/null' \
    "Group can exists" \
    "Group can does not exist"
