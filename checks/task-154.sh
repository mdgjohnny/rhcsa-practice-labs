#!/usr/bin/env bash
# Task: Log message 'This is RHCSA sample exam on <date> by <user>' to /var/log/messages
# Title: Log Custom Message
# Category: users-groups
# Target: node1


check 'id use &>/dev/null' \
    "User use exists" \
    "User use does not exist"
