#!/usr/bin/env bash
# Task: Create 200MB swap partition on secondary disk, use UUID, persistent
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
