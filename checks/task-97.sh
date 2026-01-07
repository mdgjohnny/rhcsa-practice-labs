#!/usr/bin/env bash
# Task: Find files owned by edwin, copy to /root/edwinfiles
# Title: Find Files by Owner (edwin)
# Category: essential-tools
# Target: node1


check 'id edwin &>/dev/null' \
    "User edwin exists" \
    "User edwin does not exist"
