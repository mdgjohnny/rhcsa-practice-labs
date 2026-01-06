#!/usr/bin/env bash
# Task: Configure /etc/skel so new users get a CONGRATS file in home directory
# Category: users-groups
# after user creation

check ' [[ -f /etc/skel/CONGRATS ]] ' \
    "File named CONGRATS will be in home folder after user is created" \
    "File named CONGRATS will not be in home folder after user is created"
