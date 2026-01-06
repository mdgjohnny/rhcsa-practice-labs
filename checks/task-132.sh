#!/usr/bin/env bash
# Task: Create shared group directories /groups/sales and /groups/data, and make sure the groups meet the following requirements
# Category: users-groups
# Target: node1

# Check groups exist
check \'run_ssh "$NODE1_IP" "getent group sales" &>/dev/null\' \
    "Group sales exists" \
    "Group sales does not exist"

check \'run_ssh "$NODE1_IP" "getent group data" &>/dev/null\' \
    "Group data exists" \
    "Group data does not exist"

# Check directories exist
check \'run_ssh "$NODE1_IP" "test -d /groups/sales"\' \
    "Directory /groups/sales exists" \
    "Directory /groups/sales does not exist"

check \'run_ssh "$NODE1_IP" "test -d /groups/data"\' \
    "Directory /groups/data exists" \
    "Directory /groups/data does not exist"

# Check group ownership
check \'run_ssh "$NODE1_IP" "stat -c %G /groups/sales 2>/dev/null | grep -q "sales""\' \
    "/groups/sales is owned by group sales" \
    "/groups/sales is not owned by sales"

check \'run_ssh "$NODE1_IP" "stat -c %G /groups/data 2>/dev/null | grep -q "data""\' \
    "/groups/data is owned by group data" \
    "/groups/data is not owned by data"

# Check no others access
PERMS_SALES=$(stat -c %a /groups/sales 2>/dev/null)
check '[[ "${PERMS_SALES:2:1}" == "0" ]]' \
    "/groups/sales has no access for others" \
    "/groups/sales allows access to others"

PERMS_DATA=$(stat -c %a /groups/data 2>/dev/null)
check '[[ "${PERMS_DATA:2:1}" == "0" ]]' \
    "/groups/data has no access for others" \
    "/groups/data allows access to others"
