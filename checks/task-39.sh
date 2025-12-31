#!/usr/bin/env bash
# Task: Create /groups/sales and /groups/account
# Alex can delete all files (ACL)

check '[[ -d /groups/sales ]]' \
    "Directory /groups/sales exists" \
    "Directory /groups/sales does not exist"

check '[[ -d /groups/account ]]' \
    "Directory /groups/account exists" \
    "Directory /groups/account does not exist"

check 'getent group sales &>/dev/null' \
    "Group sales exists" \
    "Group sales does not exist"

check 'getent group account &>/dev/null' \
    "Group account exists" \
    "Group account does not exist"

check 'getfacl /groups/sales 2>/dev/null | grep -q "user:alex:rwx"' \
    "User alex has full ACL on /groups/sales" \
    "User alex does not have ACL on /groups/sales"

check 'getfacl /groups/account 2>/dev/null | grep -q "user:alex:rwx"' \
    "User alex has full ACL on /groups/account" \
    "User alex does not have ACL on /groups/account"
