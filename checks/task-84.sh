#!/usr/bin/env bash
# Task: Configure user "bill" to manage users via sudo, but cannot change root password.
# Title: Configure Limited Sudo
# Category: users-groups
# Target: node1

# Check if user bill exists
check 'id bill &>/dev/null' \
    "User bill exists" \
    "User bill does not exist"

# Check if sudo config exists for bill
check 'grep -rq "bill" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "Sudo configuration for bill exists" \
    "No sudo configuration found for bill"

# Check bill has some passwd/user management permissions
check 'grep -rE "bill.*(passwd|user)" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -q bill' \
    "Bill has user management permissions" \
    "Bill does not have user management permissions"
