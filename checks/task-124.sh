#!/usr/bin/env bash
# Task: Add a new disk to your virtual machine with a size of 10 GiB. On this disk, create a LVM logical volume with a size of 5 GiB, configure it as swap, and mount it persistently
# Category: file-systems
# Target: node1


check \'run_ssh "$NODE1_IP" "swapon --show | grep -q ."\' \
    "Swap is active" \
    "No swap is active"
check \'run_ssh "$NODE1_IP" "grep -q swap /etc/fstab"\' \
    "Swap is configured in /etc/fstab" \
    "Swap is not in /etc/fstab"
