#!/usr/bin/env bash
# Task: Find all files that are owned by user linda and copy them to the file /tmp/lindafiles/
# Category: essential-tools
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
