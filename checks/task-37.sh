#!/usr/bin/env bash
# Task: Extend logical volume lv1 by 64MB without unmounting. Resize filesystem to use new space.
# Title: Extend Logical Volume Online
# Category: file-systems
# Target: node2

LV_SIZE=$(lvs --noheadings -o lv_size --units m vg1/lv1 2>/dev/null | tr -d ' m')

# Original was 10 LEs * 8MB = 80MB, extended by 64MB = ~144MB
check '[[ "${LV_SIZE%.*}" -ge 140 ]]' \
    "lv1 has been extended (size >= 140MB, got ${LV_SIZE}MB)" \
    "lv1 has not been extended sufficiently (got ${LV_SIZE}MB)"

FS_SIZE=$(df -m /mnt/lvfs1 2>/dev/null | tail -1 | awk '{print $2}')
check '[[ "$FS_SIZE" -ge 130 ]]' \
    "Filesystem on /mnt/lvfs1 has been extended" \
    "Filesystem on /mnt/lvfs1 has not been extended"
