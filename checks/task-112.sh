#!/usr/bin/env bash
# Task: Find all files owned by linda and copy to /tmp/lindafiles/
# Category: essential-tools
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
