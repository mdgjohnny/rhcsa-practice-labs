#!/usr/bin/env bash
# Task: Find all files that are owned by user edwin and copy them to the directory/ rootedwinfiles
# Category: essential-tools
# Target: node1


check 'id edwin &>/dev/null' \
    "User edwin exists" \
    "User edwin does not exist"
