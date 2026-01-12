#!/usr/bin/env bash
# Task: List the SELinux context of the /home directory and all its immediate subdirectories. Save to /root/home-contexts.txt.
# Title: List Directory SELinux Contexts
# Category: security
# Target: node1

check '[[ -f /root/home-contexts.txt ]]' \
    "File /root/home-contexts.txt exists" \
    "File not found"

check 'grep -qE "user_home_dir_t|home_root_t" /root/home-contexts.txt' \
    "File contains home directory context types" \
    "Expected context types not found"
