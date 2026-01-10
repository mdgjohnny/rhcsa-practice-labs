#!/usr/bin/env bash
# Task: Using /dev/loop0, create a 200MB swap partition. Enable persistently using UUID in /etc/fstab.
# Title: Create Swap with UUID
# Category: local-storage

check 'swapon --show | grep -q partition' \
    "Swap partition is active" \
    "No swap partition active"

check 'grep -q "swap" /etc/fstab' \
    "Swap configured in /etc/fstab" \
    "Swap not configured in /etc/fstab"

check 'grep swap /etc/fstab | grep -qi "uuid="' \
    "Swap uses UUID in /etc/fstab" \
    "Swap does not use UUID in /etc/fstab"
