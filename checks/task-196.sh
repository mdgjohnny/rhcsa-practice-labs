#!/usr/bin/env bash
# Task: Create a volume group named "datavg" using /dev/loop5 as the physical volume.
# Title: Create Volume Group
# Category: local-storage
# Target: node1
# Setup: dd if=/dev/zero of=/tmp/loop5.img bs=1M count=200; losetup /dev/loop5 /tmp/loop5.img; pvcreate /dev/loop5

check 'vgs datavg &>/dev/null' \
    "Volume group datavg exists" \
    "Volume group datavg not found"

check 'vgdisplay datavg 2>/dev/null | grep -q "/dev/loop5"' \
    "VG datavg includes /dev/loop5" \
    "VG doesn't include expected PV"
