#!/usr/bin/env bash
# Task: Configure the default umask for user "testuser" to 027, so new files are created with 640 and directories with 750 permissions. Add this to the user's .bashrc file.
# Title: Configure User Default Permissions (umask)
# Category: security
# Target: node1

check 'id testuser &>/dev/null' \
    "User testuser exists" \
    "User testuser not found (create it first)"

check 'grep -q "umask.*027" /home/testuser/.bashrc 2>/dev/null || grep -q "umask.*027" /home/testuser/.bash_profile 2>/dev/null' \
    "umask 027 configured in user profile" \
    "umask 027 not found in .bashrc or .bash_profile"

check 'su - testuser -c "umask" 2>/dev/null | grep -q "0027\|027"' \
    "umask is active for user session" \
    "umask not active (may need login shell)"
