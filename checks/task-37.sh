#!/usr/bin/env bash
# Task: On rhcsa2 - Extend lv1 by 64MB without unmounting

LV_SIZE=$(ssh "$NODE2_IP" "lvs --noheadings -o lv_size --units m vg1/lv1 2>/dev/null" | tr -d ' m')

# Original was 10 LEs * 8MB = 80MB, extended by 64MB = ~144MB
check '[[ "${LV_SIZE%.*}" -ge 140 ]]' \
    "lv1 has been extended (size >= 140MB)" \
    "lv1 has not been extended sufficiently"

check 'ssh "$NODE2_IP" "df -m /mnt/lvfs1 | tail -1 | awk \"{print \\\$2}\" | grep -q \"^1[34]\"" 2>/dev/null' \
    "Filesystem on /mnt/lvfs1 has been extended" \
    "Filesystem on /mnt/lvfs1 has not been extended"
