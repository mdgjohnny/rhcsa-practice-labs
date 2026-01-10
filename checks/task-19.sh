#!/usr/bin/env bash
# Task: Configure root prompt to display hostname, username, and current directory.
# Title: Customize Shell Prompt
# Category: essential-tools
# Update ~/.bashrc for permanence

check 'grep -q "PS1=.*\\\\h.*\\\\u.*\\\\w\|PS1=.*\\\\h.*\\\\u.*\\\\W" /root/.bashrc 2>/dev/null' \
    "Custom PS1 found in /root/.bashrc" \
    "Custom PS1 not found in /root/.bashrc"
