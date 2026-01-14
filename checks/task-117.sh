#!/usr/bin/env bash
# Task: Create users linda and anna as members of group "sales", and users serene and alex as members of group "account".
# Title: Create Users in Groups
# Category: users-groups
# Target: node1

check 'getent group sales &>/dev/null' \
    "Group sales exists" \
    "Group sales does not exist"

check 'getent group account &>/dev/null' \
    "Group account exists" \
    "Group account does not exist"

check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"

check 'id anna &>/dev/null' \
    "User anna exists" \
    "User anna does not exist"

check 'id serene &>/dev/null' \
    "User serene exists" \
    "User serene does not exist"

check 'id alex &>/dev/null' \
    "User alex exists" \
    "User alex does not exist"

check 'id -nG linda 2>/dev/null | grep -qw sales' \
    "linda is member of sales" \
    "linda is not in sales group"

check 'id -nG anna 2>/dev/null | grep -qw sales' \
    "anna is member of sales" \
    "anna is not in sales group"

check 'id -nG serene 2>/dev/null | grep -qw account' \
    "serene is member of account" \
    "serene is not in account group"

check 'id -nG alex 2>/dev/null | grep -qw account' \
    "alex is member of account" \
    "alex is not in account group"
