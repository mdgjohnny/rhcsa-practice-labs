#!/usr/bin/env bash
# Task: Create user "bob" with a restricted shell that only allows password changes (no command execution).
# Title: Create Restricted Shell User
# Category: users-groups
# Target: node1

# Check user bob exists
check 'id bob &>/dev/null' \
    "User bob exists" \
    "User bob does not exist"

# Check bob's shell is restricted (e.g., /usr/bin/passwd or similar restricted shell)
check 'getent passwd bob | grep -qE "/usr/bin/passwd|/bin/rbash|nologin|lchsh"' \
    "User bob has a restricted shell" \
    "User bob does not have a restricted shell"
