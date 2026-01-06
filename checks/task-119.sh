#!/usr/bin/env bash
# Task: Enable root SSH login
# Category: networking
# Target: node1


check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
