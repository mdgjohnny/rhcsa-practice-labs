#!/usr/bin/env bash
# Task: Using /dev/loop0 (10GiB), create a 5GiB LVM logical volume for swap. Enable persistently.
# Title: Create LVM Swap
# Category: file-systems
# Target: node1


check 'swapon --show | grep -q .' \
    "Swap is active" \
    "No swap is active"
check 'grep -q swap /etc/fstab' \
    "Swap is configured in /etc/fstab" \
    "Swap is not in /etc/fstab"
