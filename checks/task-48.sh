#!/usr/bin/env bash
# Task: Configure user20 to execute sudo commands without password prompt.
# Title: Configure Passwordless Sudo
# Category: users-groups
# Target: node1

check 'grep -rq "user20.*NOPASSWD.*ALL\|user20.*NOPASSWD:.*ALL" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "user20 can sudo without password" \
    "user20 cannot sudo without password"
