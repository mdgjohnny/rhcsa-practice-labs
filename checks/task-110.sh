#!/usr/bin/env bash
# Task: Using /dev/loop0, create a 2GiB swap partition and enable it persistently via /etc/fstab.
# Title: Create Swap Partition
# Category: file-systems
# Target: node1


check 'swapon --show | grep -q .' \
    "Swap is active" \
    "No swap is active"
check 'grep -q swap /etc/fstab' \
    "Swap is configured in /etc/fstab" \
    "Swap is not in /etc/fstab"
