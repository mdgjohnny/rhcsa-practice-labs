#!/usr/bin/env bash
# Task: Configure the system so that when new users are created, they automatically get an empty file named "NEWFILE" in their home directory.
# Title: Configure New User Template
# Category: users-groups
# Target: node1

check '[[ -f /etc/skel/NEWFILE ]]' \
    "NEWFILE will be created for new users" \
    "NEWFILE not configured for new users"

check '[[ ! -s /etc/skel/NEWFILE ]]' \
    "NEWFILE is empty as required" \
    "NEWFILE should be empty"
