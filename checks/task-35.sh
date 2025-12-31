#!/usr/bin/env bash
# Task: On rhcsa2 - Create LV lv1 (10 LEs) in vg1 (PE size 8MB)
# XFS filesystem, mount on /mnt/lvfs1

# Run checks on node2
check 'ssh "$NODE2_IP" "lvs vg1/lv1 &>/dev/null" 2>/dev/null' \
    "LV lv1 exists in vg1 on node2" \
    "LV lv1 does not exist on node2"

check 'ssh "$NODE2_IP" "vgs --noheadings -o vg_extent_size vg1 2>/dev/null | grep -q 8"' \
    "vg1 has PE size of 8MB on node2" \
    "vg1 does not have PE size of 8MB"

check 'ssh "$NODE2_IP" "mount | grep -q /mnt/lvfs1.*xfs" 2>/dev/null' \
    "/mnt/lvfs1 mounted with XFS on node2" \
    "/mnt/lvfs1 not mounted with XFS on node2"

check 'ssh "$NODE2_IP" "[[ -f /mnt/lvfs1/lv1file1 ]]" 2>/dev/null' \
    "File lv1file1 exists on node2" \
    "File lv1file1 does not exist on node2"

check 'ssh "$NODE2_IP" "grep -q /mnt/lvfs1 /etc/fstab" 2>/dev/null' \
    "/mnt/lvfs1 in /etc/fstab on node2" \
    "/mnt/lvfs1 not in /etc/fstab on node2"
