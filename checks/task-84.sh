#!/usr/bin/env bash
# Task: Create a sudo configuration that allows user bill to manage user properties and passwords, but which does not allow this user to change the password for the root user
# Category: users-groups
# Target: node1

# Check if user bill exists
check \'run_ssh "$NODE1_IP" "id bill" &>/dev/null\' \
    "User bill exists" \
    "User bill does not exist"

# Check if sudo config exists for bill
check \'run_ssh "$NODE1_IP" "grep -rq "bill" /etc/sudoers /etc/sudoers.d/ 2>/dev/null"\' \
    "Sudo configuration for bill exists" \
    "No sudo configuration found for bill"

# Check bill has some passwd/user management permissions
check \'run_ssh "$NODE1_IP" "grep -rE "bill.*(passwd|user)" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -q bill"\' \
    "Bill has user management permissions" \
    "Bill does not have user management permissions"
