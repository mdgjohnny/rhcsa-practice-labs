#!/usr/bin/env bash
# Task: Create a 1-GiB LVM volume group. In this volume group, create a 512-MiB swap volume and mount it persistently
# Category: file-systems
# Target: node1


check \'run_ssh "$NODE1_IP" "vgs in &>/dev/null"\' \
    "Volume group in exists" \
    "Volume group in does not exist"
check \'run_ssh "$NODE1_IP" "swapon --show | grep -q ."\' \
    "Swap is active" \
    "No swap is active"
check \'run_ssh "$NODE1_IP" "grep -q swap /etc/fstab"\' \
    "Swap is configured in /etc/fstab" \
    "Swap is not in /etc/fstab"
