#!/usr/bin/env bash
# Task: Create 400MiB LV "lvo2" in "vgo2". Format vfat and mount on /mnt/vfatfs.
# Title: Create VFAT Logical Volume
# Category: local-storage

check 'lvs vgo2/lvo2 &>/dev/null' \
    "Logical volume lvo2 exists in vgo2" \
    "Logical volume lvo2 does not exist"

LV_SIZE=$(lvs --noheadings -o lv_size --units m vgo2/lvo2 2>/dev/null | tr -d ' m')
check '[[ "${LV_SIZE%.*}" -ge 390 ]] && [[ "${LV_SIZE%.*}" -le 420 ]]' \
    "lvo2 is approximately 400MiB" \
    "lvo2 size is not approximately 400MiB"

check 'mount | grep -q "/mnt/vfatfs.*vfat"' \
    "/mnt/vfatfs is mounted with vfat" \
    "/mnt/vfatfs is not mounted with vfat"

check 'grep -q "/mnt/vfatfs" /etc/fstab' \
    "/mnt/vfatfs is in /etc/fstab (persistent)" \
    "/mnt/vfatfs is not in /etc/fstab"
