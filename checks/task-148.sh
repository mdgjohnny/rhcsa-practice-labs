#!/usr/bin/env bash
# Task: Using /dev/loop0, create 280MB LV "lvol1" in "vgtest" VG. Format ext4 and mount on /mnt/mnt1.
# Title: Create and Mount Logical Volume
# Category: file-systems
# Target: node1


check 'vgs mount &>/dev/null' \
    "Volume group mount exists" \
    "Volume group mount does not exist"
