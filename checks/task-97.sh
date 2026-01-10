#!/usr/bin/env bash
# Task: Find all files owned by user "edwin" and copy to /root/edwinfiles/.
# Title: Find Files by Owner
# Category: essential-tools
# Target: node1


check 'id edwin &>/dev/null' \
    "User edwin exists" \
    "User edwin does not exist"
