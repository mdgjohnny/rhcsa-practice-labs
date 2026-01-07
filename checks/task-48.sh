#!/usr/bin/env bash
# Task: Allow user20 to use sudo without password prompt
# Title: Passwordless Sudo (user20)
# Category: users-groups

check 'grep -rq "user20.*NOPASSWD.*ALL\|user20.*NOPASSWD:.*ALL" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "user20 can sudo without password" \
    "user20 cannot sudo without password"
