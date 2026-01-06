#!/usr/bin/env bash
# Task: Grant user laura full sudo privileges
# Category: users-groups
# Target: node1


check 'id laura &>/dev/null' \
    "User laura exists" \
    "User laura does not exist"
check 'grep -rq "laura" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "Sudo config for laura exists" \
    "No sudo config for laura"
