#!/usr/bin/env bash
# Task: Resize the LVM logical volume that contains the root file system and add 1 GiB. Perform all tasks necessary to do so
# Category: file-systems
# Target: node1


check \'run_ssh "$NODE1_IP" "lvs | grep -q that"\' \
    "Logical volume that exists" \
    "Logical volume that does not exist"
