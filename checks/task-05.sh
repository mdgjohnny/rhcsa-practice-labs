#!/usr/bin/env bash
# Task: Configure the system so that the hostname "rhcsa2" resolves to rhcsa2's IP address.
# Title: Configure Host Resolution
# Category: networking
# Target: node1

check 'ping -c1 -W2 rhcsa2 &>/dev/null' \
    "Can ping rhcsa2 by hostname" \
    "Cannot ping rhcsa2 by hostname"
