#!/usr/bin/env bash
# Task: Create directories /users/user1 through /users/user5.
# Title: Create Directory Structure
# Category: users-groups
# Target: node1


check '[[ -d /users/ ]]' \
    "Directory /users/ exists" \
    "Directory /users/ does not exist"
