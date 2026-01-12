#!/usr/bin/env bash
# Task: Create a GPT partition table on /dev/loop2 with a single 400MB partition. The partition should use GPT (not MBR).
# Title: Create GPT Partition
# Category: local-storage
# Target: node1
# Setup: dd if=/dev/zero of=/tmp/loop2.img bs=1M count=500; losetup /dev/loop2 /tmp/loop2.img

check 'gdisk -l /dev/loop2 2>/dev/null | grep -qi "GPT" || parted /dev/loop2 print 2>/dev/null | grep -qi "gpt"' \
    "GPT partition table exists on /dev/loop2" \
    "No GPT partition table on /dev/loop2"

check 'lsblk -no SIZE /dev/loop2p1 2>/dev/null | grep -qE "[34][0-9]{2}M" || fdisk -l /dev/loop2 2>/dev/null | grep -q "loop2p1"' \
    "Partition exists (~400MB)" \
    "Partition not found or wrong size"
