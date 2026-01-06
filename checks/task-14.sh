#!/usr/bin/env bash
# Task: Create user bob with shell that only allows password change
# Category: users-groups

check \'run_ssh "$NODE1_IP" "id bob" &>/dev/null\' \
    "User bob exists" \
    "User bob does not exist"

check \'run_ssh "$NODE1_IP" "getent passwd bob" | grep -q "/usr/bin/lchsh\|/bin/lchsh"\' \
    "User bob has restricted shell (lchsh)" \
    "User bob does not have restricted shell"
