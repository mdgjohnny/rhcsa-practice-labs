#!/usr/bin/env bash
# Task: Create /groups/sales and /groups/account with proper group ownership and permissions.
# Title: Create Shared Group Directories
# Category: users-groups
# Target: node1

# Check groups exist
check 'getent group sales &>/dev/null' \
    "Group sales exists" \
    "Group sales does not exist"

check 'getent group account &>/dev/null' \
    "Group account exists" \
    "Group account does not exist"

# Check directories exist
check '[[ -d /groups/sales ]]' \
    "Directory /groups/sales exists" \
    "Directory /groups/sales does not exist"

check '[[ -d /groups/account ]]' \
    "Directory /groups/account exists" \
    "Directory /groups/account does not exist"

# Check group ownership
check 'stat -c %G /groups/sales 2>/dev/null | grep -q "sales"' \
    "/groups/sales is owned by group sales" \
    "/groups/sales is not owned by sales"

check 'stat -c %G /groups/account 2>/dev/null | grep -q "account"' \
    "/groups/account is owned by group account" \
    "/groups/account is not owned by account"

# Check SGID bit for group inheritance
check 'stat -c %a /groups/sales 2>/dev/null | grep -q "^2"' \
    "/groups/sales has SGID bit set" \
    "/groups/sales does not have SGID bit"

check 'stat -c %a /groups/account 2>/dev/null | grep -q "^2"' \
    "/groups/account has SGID bit set" \
    "/groups/account does not have SGID bit"
