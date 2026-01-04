#!/usr/bin/env bash
# Task: Create a logical volume called lvswap of size 280MB in vgtest volume group. Initialize the logical volume for swap use. Use the UUID and place an entry for persistence
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
