#!/usr/bin/env bash
# Task: Create 200MB swap partition on secondary disk, use UUID, persistent
# Category: local-storage

check \'run_ssh "$NODE1_IP" "swapon --show | grep -q partition"\' \
    "Swap partition is active" \
    "No swap partition active"

check \'run_ssh "$NODE1_IP" "grep -q "swap" /etc/fstab"\' \
    "Swap configured in /etc/fstab" \
    "Swap not configured in /etc/fstab"

check \'run_ssh "$NODE1_IP" "grep swap /etc/fstab | grep -qi "uuid=""\' \
    "Swap uses UUID in /etc/fstab" \
    "Swap does not use UUID in /etc/fstab"
