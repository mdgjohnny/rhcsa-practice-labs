#!/usr/bin/env bash
# Task: Configure /etc/hosts so node1 can ping rhcsa2 by hostname
# Title: Configure /etc/hosts (node1)
# Category: networking
# Target: node1

check 'ping -c1 -W2 rhcsa2 &>/dev/null' \
    "Can ping rhcsa2 by hostname" \
    "Cannot ping rhcsa2 by hostname (check /etc/hosts)"
