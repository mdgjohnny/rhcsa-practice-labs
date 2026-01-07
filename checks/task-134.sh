#!/usr/bin/env bash
# Task: Create 1GiB VG with 512MiB swap LV, mount persistently
# Title: LVM Swap Volume
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
