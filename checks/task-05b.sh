#!/usr/bin/env bash
# Task: Configure /etc/hosts so node2 can ping rhcsa1 by hostname
# Title: Configure /etc/hosts (node2)
# Category: networking
# Target: node2

check 'ping -c1 -W2 rhcsa1 &>/dev/null' \
    "Can ping rhcsa1 by hostname" \
    "Cannot ping rhcsa1 by hostname (check /etc/hosts)"
