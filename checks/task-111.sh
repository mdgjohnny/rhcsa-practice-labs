#!/usr/bin/env bash
# Task: Extend the root logical volume by 1GiB. The filesystem must be resized to use the new space.
# Title: Extend Logical Volume
# Category: file-systems
# Target: node1


check 'lvs | grep -q that' \
    "Logical volume that exists" \
    "Logical volume that does not exist"
