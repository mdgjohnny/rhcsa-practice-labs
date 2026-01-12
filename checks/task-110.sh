#!/usr/bin/env bash
# Task: Create a 2GiB swap space using /dev/loop0. The swap must be active and persist across reboots.
# Title: Create Swap Space
# Category: file-systems
# Target: node1

check 'swapon --show | grep -q loop0' \
    "Swap on loop0 is active" \
    "Swap on loop0 is not active"

check 'grep -q loop0 /etc/fstab && grep loop0 /etc/fstab | grep -q swap' \
    "Swap is configured to persist" \
    "Swap is not configured to persist"
