#!/usr/bin/env bash
# Task: Create a configuration that allows user laura to run all administrative commands using sudo
# Category: users-groups
# Target: node1


check \'run_ssh "$NODE1_IP" "id laura" &>/dev/null\' \
    "User laura exists" \
    "User laura does not exist"
check \'run_ssh "$NODE1_IP" "grep -rq "laura" /etc/sudoers /etc/sudoers.d/ 2>/dev/null"\' \
    "Sudo config for laura exists" \
    "No sudo config for laura"
