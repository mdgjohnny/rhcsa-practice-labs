#!/usr/bin/env bash
# Task: Create shared group directories /groups/livingopensource and /groups/operations and make sure these groups meet the following requirements
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

# Check sticky bit for "delete only own files"
check \'run_ssh "$NODE1_IP" "stat -c %a /groups/livingopensource 2>/dev/null | grep -q "1...$\|^1""\' \
    "/groups/livingopensource has sticky bit" \
    "/groups/livingopensource missing sticky bit"

check \'run_ssh "$NODE1_IP" "stat -c %a /groups/operations 2>/dev/null | grep -q "1...$\|^1""\' \
    "/groups/operations has sticky bit" \
    "/groups/operations missing sticky bit"
