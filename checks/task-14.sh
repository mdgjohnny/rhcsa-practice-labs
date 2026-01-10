#!/usr/bin/env bash
# Task: Create user "bob" with a shell that only allows password changes, preventing normal command execution.
# Title: Create Restricted User
# Category: users-groups
# Target: node1

check 'id bob &>/dev/null' \
    "User bob exists" \
    "User bob does not exist"

check 'getent passwd bob | grep -q "/usr/bin/lchsh\|/bin/lchsh"' \
    "User bob has restricted shell (lchsh)" \
    "User bob does not have restricted shell"
