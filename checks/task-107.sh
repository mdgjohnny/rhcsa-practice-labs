#!/usr/bin/env bash
# Task: Configure /etc/skel to copy NEWFILE to new user home directories
# Title: Configure /etc/skel (NEWFILE)
# Category: users-groups
# Target: node1

# Check if NEWFILE exists in /etc/skel
check '[[ -f /etc/skel/NEWFILE ]]' \
    "NEWFILE exists in /etc/skel" \
    "NEWFILE does not exist in /etc/skel"

# Check the file is empty (0 bytes)
check '[[ ! -s /etc/skel/NEWFILE ]]' \
    "NEWFILE is empty" \
    "NEWFILE is not empty"
