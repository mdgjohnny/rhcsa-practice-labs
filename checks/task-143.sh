#!/usr/bin/env bash
# Task: Configure root shell prompt to show hostname, username, and working directory.
# Title: Customize Shell Prompt
# Category: networking
# Target: node1


check 'id initialization &>/dev/null' \
    "User initialization exists" \
    "User initialization does not exist"
