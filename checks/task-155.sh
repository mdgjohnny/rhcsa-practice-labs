#!/usr/bin/env bash
# Task: Allow user20 to use sudo without being prompted for their password.)
# Category: users-groups
# Target: node1


check \'run_ssh "$NODE1_IP" "grep -rq "user20" /etc/sudoers /etc/sudoers.d/ 2>/dev/null"\' \
    "Sudo config for user20 exists" \
    "No sudo config for user20"
