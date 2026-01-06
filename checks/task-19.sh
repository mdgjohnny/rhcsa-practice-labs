#!/usr/bin/env bash
# Task: Change root prompt to show hostname, username, current dir
# Category: essential-tools
# Update ~/.bashrc for permanence

check \'run_ssh "$NODE1_IP" "grep -q "PS1=.*\\\\h.*\\\\u.*\\\\w\|PS1=.*\\\\h.*\\\\u.*\\\\W" /root/.bashrc 2>/dev/null"\' \
    "Custom PS1 found in /root/.bashrc" \
    "Custom PS1 not found in /root/.bashrc"
