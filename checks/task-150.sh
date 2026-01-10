#!/usr/bin/env bash
# Task: Create 280MB swap LV "lvswap" in "vgtest". Mount persistently using UUID.
# Title: Create Swap LV with UUID
# Category: file-systems
# Target: node1

# Check volume group vgtest exists
check 'vgs vgtest &>/dev/null' \
    "Volume group vgtest exists" \
    "Volume group vgtest does not exist"

# Check logical volume lvswap exists
check 'lvs vgtest/lvswap &>/dev/null' \
    "Logical volume lvswap exists in vgtest" \
    "Logical volume lvswap does not exist"

# Check swap is active
check 'swapon --show | grep -q "lvswap\|vgtest"' \
    "lvswap is active as swap" \
    "lvswap is not active as swap"

# Check persistent mount uses UUID in fstab
check 'grep -q "swap.*UUID\|UUID.*swap" /etc/fstab' \
    "Swap entry uses UUID in /etc/fstab" \
    "Swap entry not using UUID in /etc/fstab"
