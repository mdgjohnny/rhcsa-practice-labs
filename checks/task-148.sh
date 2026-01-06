#!/usr/bin/env bash
# Task: Create a logical volume called lvol1 of size 280MB in vgtest volume group. Mount the ext4 file system persistently to /mnt/mnt1
# Category: file-systems
# Target: node1


check \'run_ssh "$NODE1_IP" "vgs mount &>/dev/null"\' \
    "Volume group mount exists" \
    "Volume group mount does not exist"
