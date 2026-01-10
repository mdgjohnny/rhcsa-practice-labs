#!/usr/bin/env bash
# Task: Add an entry to /etc/hosts so that "rhcsa1" resolves to the correct IP address. Verify with: ping rhcsa1
# Title: Configure Host Resolution
# Category: networking
# Target: node2

check 'ping -c1 -W2 rhcsa1 &>/dev/null' \
    "Can ping rhcsa1 by hostname" \
    "Cannot ping rhcsa1 by hostname (check /etc/hosts)"
