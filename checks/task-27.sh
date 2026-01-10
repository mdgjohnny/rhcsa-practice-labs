#!/usr/bin/env bash
# Task: Using /dev/loop0, create a 280MB LV "lvol1" in VG "vgtest". Format ext4 and mount on /mnt/mnt1.
# Title: Create Logical Volume
# Category: local-storage

check 'lvs vgtest/lvol1 &>/dev/null' \
    "Logical volume lvol1 exists in vgtest" \
    "Logical volume lvol1 does not exist"

LV_SIZE=$(lvs --noheadings -o lv_size --units m vgtest/lvol1 2>/dev/null | tr -d ' m')
check '[[ "${LV_SIZE%.*}" -ge 270 ]] && [[ "${LV_SIZE%.*}" -le 300 ]]' \
    "lvol1 is approximately 280MB" \
    "lvol1 size is not approximately 280MB"

check 'mount | grep -q "/mnt/mnt1.*ext4"' \
    "/mnt/mnt1 is mounted with ext4" \
    "/mnt/mnt1 is not mounted with ext4"

check 'grep -q "/mnt/mnt1" /etc/fstab' \
    "/mnt/mnt1 is in /etc/fstab (persistent)" \
    "/mnt/mnt1 is not in /etc/fstab"
