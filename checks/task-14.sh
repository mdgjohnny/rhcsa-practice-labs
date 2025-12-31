#!/usr/bin/env bash
# Task: Create user bob with shell that only allows password change

check 'id bob &>/dev/null' \
    "User bob exists" \
    "User bob does not exist"

check 'getent passwd bob | grep -q "/usr/bin/lchsh\|/bin/lchsh"' \
    "User bob has restricted shell (lchsh)" \
    "User bob does not have restricted shell"
