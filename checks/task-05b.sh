#!/usr/bin/env bash
# Task: Configure the system so that the hostname "rhcsa1" resolves to rhcsa1's IP address.
# Title: Configure Host Resolution
# Category: networking
# Target: node2

check 'ping -c1 -W2 rhcsa1 &>/dev/null' \
    "Can ping rhcsa1 by hostname" \
    "Cannot ping rhcsa1 by hostname"
