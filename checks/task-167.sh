#!/usr/bin/env bash
# Task: Create a symbolic link /root/passwd-link that points to /etc/passwd. The link should work correctly to read the password file.
# Title: Create Symbolic Link
# Category: essential-tools
# Target: node1

check '[[ -L /root/passwd-link ]]' \
    "Symbolic link /root/passwd-link exists" \
    "Symbolic link /root/passwd-link not found"

check '[[ $(readlink /root/passwd-link) == "/etc/passwd" ]]' \
    "Link points to /etc/passwd" \
    "Link does not point to /etc/passwd"

check 'cat /root/passwd-link | grep -q "root:"' \
    "Link is functional (can read through it)" \
    "Link is broken or not readable"
