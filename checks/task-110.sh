#!/usr/bin/env bash
# Task: Create a 2-GiB swap partition and mount it persistently
# Category: file-systems
# Target: node1


check 'swapon --show | grep -q .' \
    "Swap is active" \
    "No swap is active"
check 'grep -q swap /etc/fstab' \
    "Swap is configured in /etc/fstab" \
    "Swap is not in /etc/fstab"
