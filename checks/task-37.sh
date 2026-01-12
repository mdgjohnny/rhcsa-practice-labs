#!/usr/bin/env bash
# Task: Extend LV "lv1" in VG "vg1" (from task-35) by 64MB without unmounting. Use lvextend and xfs_growfs.
# Title: Extend Logical Volume Online
# Category: file-systems
# Target: node2

LV_SIZE=$(lvs --noheadings -o lv_size --units m vg1/lv1 2>/dev/null | tr -d ' m')

# Original was 10 LEs * 8MB = 80MB, extended by 64MB = ~144MB
check '[[ "${LV_SIZE%.*}" -ge 140 ]]' \
    "LV lv1 extended to >= 140MB (${LV_SIZE}MB)" \
    "LV lv1 too small (${LV_SIZE:-0}MB, need >= 140MB)"

FS_SIZE=$(df -m /mnt/lvfs1 2>/dev/null | tail -1 | awk '{print $2}')
check '[[ "${FS_SIZE:-0}" -ge 130 ]]' \
    "Filesystem on /mnt/lvfs1 extended (${FS_SIZE}MB)" \
    "Filesystem on /mnt/lvfs1 not extended (${FS_SIZE:-0}MB)"
