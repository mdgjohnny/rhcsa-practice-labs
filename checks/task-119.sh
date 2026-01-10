#!/usr/bin/env bash
# Task: Configure SSH to permit root login with password authentication.
# Title: Enable Root SSH Login
# Category: networking
# Target: node1


check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
