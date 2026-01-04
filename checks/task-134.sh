#!/usr/bin/env bash
# Task: Create a 1-GiB LVM volume group. In this volume group, create a 512-MiB swap volume and mount it persistently
# Category: file-systems
# Target: node1


check 'vgs in &>/dev/null' \
    "Volume group in exists" \
    "Volume group in does not exist"
check 'swapon --show | grep -q .' \
    "Swap is active" \
    "No swap is active"
check 'grep -q swap /etc/fstab' \
    "Swap is configured in /etc/fstab" \
    "Swap is not in /etc/fstab"
