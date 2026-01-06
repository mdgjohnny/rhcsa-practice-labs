#!/usr/bin/env bash
# Task: All new users should have a file named CONGRATS in their home folder
# Category: users-groups
# after user creation

check ' [[ -f /etc/skel/CONGRATS ]] ' \
    "File named CONGRATS will be in home folder after user is created" \
    "File named CONGRATS will not be in home folder after user is created"
