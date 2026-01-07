#!/usr/bin/env bash
# Task: Create 5GiB LVM swap on new 10GiB disk, mount persistently
# Title: LVM Swap on New Disk
# Category: file-systems
# Target: node1


check 'swapon --show | grep -q .' \
    "Swap is active" \
    "No swap is active"
check 'grep -q swap /etc/fstab' \
    "Swap is configured in /etc/fstab" \
    "Swap is not in /etc/fstab"
