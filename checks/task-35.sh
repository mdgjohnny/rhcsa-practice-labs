#!/usr/bin/env bash
# Task: Create LV lv1 (10 LEs) in vg1 (PE size 8MB), XFS filesystem, mount on /mnt/lvfs1
# Title: Create LV (custom PE size)
# Category: local-storage
# Target: node2

check 'lvs vg1/lv1 &>/dev/null' \
    "LV lv1 exists in vg1" \
    "LV lv1 does not exist"

check 'vgs --noheadings -o vg_extent_size vg1 2>/dev/null | grep -q 8' \
    "vg1 has PE size of 8MB" \
    "vg1 does not have PE size of 8MB"

check 'mount | grep -q "/mnt/lvfs1.*xfs"' \
    "/mnt/lvfs1 mounted with XFS" \
    "/mnt/lvfs1 not mounted with XFS"

check '[[ -f /mnt/lvfs1/lv1file1 ]]' \
    "File lv1file1 exists" \
    "File lv1file1 does not exist"

check 'grep -q /mnt/lvfs1 /etc/fstab' \
    "/mnt/lvfs1 in /etc/fstab" \
    "/mnt/lvfs1 not in /etc/fstab"
