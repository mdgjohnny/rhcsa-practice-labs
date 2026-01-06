#!/usr/bin/env bash
# Task: Create /users/user1 through /users/user5 directories
# Category: users-groups
# Target: node1


check '[[ -d /users/ ]]' \
    "Directory /users/ exists" \
    "Directory /users/ does not exist"
