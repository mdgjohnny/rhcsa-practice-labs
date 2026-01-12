#!/usr/bin/env bash
# Task: Using scp, copy /etc/hosts from rhcsa2 to /tmp/hosts.remote on this system. SSH keys are already configured between nodes.
# Title: Secure Copy from Remote System
# Category: operate-systems
# Target: node1

check '[[ -f /tmp/hosts.remote ]]' \
    "File /tmp/hosts.remote exists" \
    "File /tmp/hosts.remote not found"

check 'grep -q "rhcsa2\|localhost" /tmp/hosts.remote' \
    "File contains valid hosts content" \
    "File doesn't appear to be a hosts file"

check 'diff /tmp/hosts.remote <(ssh rhcsa2 cat /etc/hosts 2>/dev/null) &>/dev/null' \
    "File matches remote /etc/hosts" \
    "File content doesn't match remote hosts"
