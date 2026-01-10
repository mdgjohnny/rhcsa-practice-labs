#!/usr/bin/env bash
# Task: Add an entry to /etc/hosts so that "rhcsa2" resolves to the correct IP address. Verify with: ping rhcsa2
# Title: Configure Host Resolution
# Category: networking
# Target: node1

check 'ping -c1 -W2 rhcsa2 &>/dev/null' \
    "Can ping rhcsa2 by hostname" \
    "Cannot ping rhcsa2 by hostname (check /etc/hosts)"
