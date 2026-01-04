#!/usr/bin/env bash
# Task: Create a directory /users/ and in this directory create the directories user1 through user5 using one command
# Category: users-groups
# Target: node1


check '[[ -d /users/ ]]' \
    "Directory /users/ exists" \
    "Directory /users/ does not exist"
