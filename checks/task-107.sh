#!/usr/bin/env bash
# Task: Set default values for new users. Ensure that an empty file with the name NEWFILE is copied to the home directory of each new user that is created
# Category: users-groups
# Target: node1

# Check if NEWFILE exists in /etc/skel
check \'run_ssh "$NODE1_IP" "test -f /etc/skel/NEWFILE"\' \
    "NEWFILE exists in /etc/skel" \
    "NEWFILE does not exist in /etc/skel"

# Check the file is empty (0 bytes)
check '[[ ! -s /etc/skel/NEWFILE ]]' \
    "NEWFILE is empty" \
    "NEWFILE is not empty"
