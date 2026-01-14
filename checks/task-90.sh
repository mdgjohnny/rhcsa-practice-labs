#!/usr/bin/env bash
# Task: Create a user named "devuser" with password "password123". The user should have a home directory and be able to login.
# Title: Create User with Password
# Category: users-groups
# Target: node1

check 'id devuser &>/dev/null' \
    "User devuser exists" \
    "User devuser does not exist"

check '[[ -d /home/devuser ]]' \
    "Home directory /home/devuser exists" \
    "Home directory not created"

check 'getent shadow devuser 2>/dev/null | grep -qvE ":!:|:\*:"' \
    "devuser has a password set (not locked)" \
    "devuser password not set or account locked"
