#!/usr/bin/env bash
# Task: Create 280MB LV lvol1 in vgtest, format ext4, mount on /mnt/mnt1
# Title: Create LV & Mount (lvol1)
# Category: file-systems
# Target: node1


check 'vgs mount &>/dev/null' \
    "Volume group mount exists" \
    "Volume group mount does not exist"
