#!/usr/bin/env bash
# Task: Create group "group10" and add user20 and user30 as secondary group members.
# Title: Create Group with Members
# Category: users-groups
# Target: node1


check 'getent group group10 &>/dev/null' \
    "Group group10 exists" \
    "Group group10 does not exist"
