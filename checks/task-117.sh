#!/usr/bin/env bash
# Task: Create users linda/anna in sales group, serene/alex in account group
# Title: Create Users (sales/account groups)
# Category: users-groups
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
check 'id serene &>/dev/null' \
    "User serene exists" \
    "User serene does not exist"
check 'getent group sales &>/dev/null' \
    "Group sales exists" \
    "Group sales does not exist"
check 'getent group account &>/dev/null' \
    "Group account exists" \
    "Group account does not exist"
