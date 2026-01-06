#!/usr/bin/env bash
# Task: Extend root LVM logical volume by 1GiB
# Category: file-systems
# Target: node1


check 'lvs | grep -q that' \
    "Logical volume that exists" \
    "Logical volume that does not exist"
