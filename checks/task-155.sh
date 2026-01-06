#!/usr/bin/env bash
# Task: Configure passwordless sudo for user20
# Category: users-groups
# Target: node1


check 'grep -rq "user20" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "Sudo config for user20 exists" \
    "No sudo config for user20"
