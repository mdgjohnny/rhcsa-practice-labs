#!/usr/bin/env bash
# Task: Create shared group directories /groups/livingopensource and /groups/operations, and make sure the groups meet the following requirements
# Category: users-groups
# Target: node1

# Check groups exist
check \'run_ssh "$NODE1_IP" "getent group livingopensource" &>/dev/null\' \
    "Group livingopensource exists" \
    "Group livingopensource does not exist"

check \'run_ssh "$NODE1_IP" "getent group operations" &>/dev/null\' \
    "Group operations exists" \
    "Group operations does not exist"

# Check directories exist
check \'run_ssh "$NODE1_IP" "test -d /groups/livingopensource"\' \
    "Directory /groups/livingopensource exists" \
    "Directory /groups/livingopensource does not exist"

check \'run_ssh "$NODE1_IP" "test -d /groups/operations"\' \
    "Directory /groups/operations exists" \
    "Directory /groups/operations does not exist"

# Check group ownership
check \'run_ssh "$NODE1_IP" "stat -c %G /groups/livingopensource 2>/dev/null | grep -q "livingopensource""\' \
    "/groups/livingopensource owned by group livingopensource" \
    "/groups/livingopensource not owned by livingopensource"

check \'run_ssh "$NODE1_IP" "stat -c %G /groups/operations 2>/dev/null | grep -q "operations""\' \
    "/groups/operations owned by group operations" \
    "/groups/operations not owned by operations"
