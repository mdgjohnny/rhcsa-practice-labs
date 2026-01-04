#!/usr/bin/env bash
# Task: Change the primary command prompt for the root user to display the hostname, username, and current working directory information in that order. Update the per-user initialization file for permanence
# Category: networking
# Target: node1


check 'id initialization &>/dev/null' \
    "User initialization exists" \
    "User initialization does not exist"
