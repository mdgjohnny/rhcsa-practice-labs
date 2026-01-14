#!/usr/bin/env bash
# Task: Create a loop device-backed VG named "vg1" with 8MB physical extent size. Create LV "lv1" using 10 extents. Format it as XFS, mount persistently on /mnt/lvfs1, and create a test file /mnt/lvfs1/testfile.
# Title: Create LVM with Custom PE Size
# Category: local-storage
# Target: node2

check 'vgs vg1 &>/dev/null' \
    "VG vg1 exists" \
    "VG vg1 does not exist"

check 'vgs --noheadings -o vg_extent_size vg1 2>/dev/null | grep -qE "8\.00m|8m"' \
    "vg1 has PE size of 8MB" \
    "vg1 does not have 8MB PE size"

check 'lvs vg1/lv1 &>/dev/null' \
    "LV lv1 exists in vg1" \
    "LV lv1 does not exist"

check 'mount | grep -qE "/mnt/lvfs1.*xfs"' \
    "/mnt/lvfs1 mounted with XFS" \
    "/mnt/lvfs1 not mounted or not XFS"

check 'grep -q /mnt/lvfs1 /etc/fstab' \
    "/mnt/lvfs1 in /etc/fstab (persistent)" \
    "/mnt/lvfs1 not in /etc/fstab"

check '[[ -f /mnt/lvfs1/testfile ]]' \
    "Test file exists in /mnt/lvfs1" \
    "Test file not found - create any file in the mount"
