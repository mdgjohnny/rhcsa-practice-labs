#!/usr/bin/env bash
# Task: Create LV lvol1 (280MB) in vgtest, mount ext4 on /mnt/mnt1
# Title: Create LV & Mount (ext4)
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
