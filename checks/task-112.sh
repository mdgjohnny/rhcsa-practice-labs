#!/usr/bin/env bash
# Task: Find all files owned by user "linda" and copy them to /tmp/lindafiles/. Preserve file attributes.
# Title: Find Files by Owner
# Category: essential-tools
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
