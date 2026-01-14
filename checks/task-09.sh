#!/usr/bin/env bash
# Task: Ensure that when new user accounts are created, they automatically receive a welcome file named "CONGRATS" in their home directory.
# Title: Configure New User Defaults
# Category: users-groups
# Target: node1

check '[[ -f /etc/skel/CONGRATS ]]' \
    "New users will receive CONGRATS file" \
    "CONGRATS file not configured for new users"
