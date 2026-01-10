#!/usr/bin/env bash
# Task: Configure root shell prompt to show hostname, username, and working directory.
# Title: Customize Shell Prompt
# Category: essential-tools
# Target: node1

check 'grep -q "PS1=.*\\\\h.*\\\\u.*\\\\w\|PS1=.*\\\\h.*\\\\u.*\\\\W" /root/.bashrc 2>/dev/null' \
    "Custom PS1 found in /root/.bashrc" \
    "Custom PS1 not found in /root/.bashrc"
