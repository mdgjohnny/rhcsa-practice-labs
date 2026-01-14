#!/usr/bin/env bash
# Task: Copy /etc/hosts from rhcsa2 to /tmp/hosts.remote on this system.
# Title: Copy File from Remote System
# Category: networking
# Target: node1

check '[[ -f /tmp/hosts.remote ]]' \
    "File /tmp/hosts.remote exists" \
    "File /tmp/hosts.remote not found"

check '[[ -s /tmp/hosts.remote ]]' \
    "File has content" \
    "File is empty"

check 'grep -qE "rhcsa2|localhost" /tmp/hosts.remote' \
    "File contains valid hosts content" \
    "File doesn't look like a hosts file"
