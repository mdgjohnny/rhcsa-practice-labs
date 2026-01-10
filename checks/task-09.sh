#!/usr/bin/env bash
# Task: Configure /etc/skel so that all new users automatically get a file named "CONGRATS" in their home directory.
# Title: Configure Skeleton Directory
# Category: users-groups
# Target: node1
# after user creation

check ' [[ -f /etc/skel/CONGRATS ]] ' \
    "File named CONGRATS will be in home folder after user is created" \
    "File named CONGRATS will not be in home folder after user is created"
