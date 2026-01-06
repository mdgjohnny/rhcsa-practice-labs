#!/usr/bin/env bash
# Task: Create shared group directories /groups/sales and /groups/account, and make sure these groups meet the following requirements
# Category: users-groups
# Target: node1

# Check groups exist
check \'run_ssh "$NODE1_IP" "getent group sales" &>/dev/null\' \
    "Group sales exists" \
    "Group sales does not exist"

check \'run_ssh "$NODE1_IP" "getent group account" &>/dev/null\' \
    "Group account exists" \
    "Group account does not exist"

# Check directories exist
check \'run_ssh "$NODE1_IP" "test -d /groups/sales"\' \
    "Directory /groups/sales exists" \
    "Directory /groups/sales does not exist"

check \'run_ssh "$NODE1_IP" "test -d /groups/account"\' \
    "Directory /groups/account exists" \
    "Directory /groups/account does not exist"

# Check group ownership
check \'run_ssh "$NODE1_IP" "stat -c %G /groups/sales 2>/dev/null | grep -q "sales""\' \
    "/groups/sales is owned by group sales" \
    "/groups/sales is not owned by sales"

check \'run_ssh "$NODE1_IP" "stat -c %G /groups/account 2>/dev/null | grep -q "account""\' \
    "/groups/account is owned by group account" \
    "/groups/account is not owned by account"

# Check SGID bit for group inheritance
check \'run_ssh "$NODE1_IP" "stat -c %a /groups/sales 2>/dev/null | grep -q "^2""\' \
    "/groups/sales has SGID bit set" \
    "/groups/sales does not have SGID bit"

check \'run_ssh "$NODE1_IP" "stat -c %a /groups/account 2>/dev/null | grep -q "^2""\' \
    "/groups/account has SGID bit set" \
    "/groups/account does not have SGID bit"
