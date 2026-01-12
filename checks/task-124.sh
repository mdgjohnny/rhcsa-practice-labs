#!/usr/bin/env bash
# Task: Using /dev/loop0, create VG "swapvg" and a 5GB LV "swaplv" formatted as swap. Enable swap persistently.
# Title: Create LVM Swap
# Category: file-systems
# Target: node1

check 'vgs swapvg &>/dev/null' \
    "Volume group 'swapvg' exists" \
    "Volume group 'swapvg' does not exist"

check 'lvs swapvg/swaplv &>/dev/null' \
    "Logical volume 'swaplv' exists" \
    "Logical volume 'swaplv' does not exist"

check 'swapon --show | grep -q swaplv' \
    "Swap on 'swaplv' is active" \
    "Swap on 'swaplv' is not active"

check 'grep -qE "swaplv|swapvg" /etc/fstab && grep -q swap /etc/fstab' \
    "Swap LV is configured to persist" \
    "Swap LV is not configured to persist"
