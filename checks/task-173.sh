#!/usr/bin/env bash
# Task: Using /dev/loop1, create a 500MB ext4 filesystem. Label it "myext4" and mount it persistently at /mnt/ext4data.
# Title: Create ext4 Filesystem
# Category: file-systems
# Target: node1
# Setup: dd if=/dev/zero of=/tmp/loop1.img bs=1M count=600; losetup /dev/loop1 /tmp/loop1.img

check 'blkid /dev/loop1 2>/dev/null | grep -qi "ext4"' \
    "ext4 filesystem exists on /dev/loop1" \
    "No ext4 filesystem on /dev/loop1"

check 'blkid /dev/loop1 2>/dev/null | grep -qi "myext4"' \
    "Filesystem has label myext4" \
    "Filesystem label is not myext4"

check '[[ -d /mnt/ext4data ]] && mountpoint -q /mnt/ext4data' \
    "/mnt/ext4data is mounted" \
    "/mnt/ext4data is not mounted"

check 'grep -q "/mnt/ext4data.*ext4" /etc/fstab' \
    "Mount is persistent in /etc/fstab" \
    "Mount not found in /etc/fstab"
