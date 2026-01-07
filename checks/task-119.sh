#!/usr/bin/env bash
# Task: Enable root SSH login
# Title: Enable Root SSH Login
# Category: networking
# Target: node1


check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
