#!/usr/bin/env bash
# Task: Create LV lvo2 (400MiB) in vgo2, mount vfat on /mnt/vfatfs
# Category: local-storage

check \'run_ssh "$NODE1_IP" "lvs vgo2/lvo2 &>/dev/null"\' \
    "Logical volume lvo2 exists in vgo2" \
    "Logical volume lvo2 does not exist"

LV_SIZE=$(lvs --noheadings -o lv_size --units m vgo2/lvo2 2>/dev/null | tr -d ' m')
check '[[ "${LV_SIZE%.*}" -ge 390 ]] && [[ "${LV_SIZE%.*}" -le 420 ]]' \
    "lvo2 is approximately 400MiB" \
    "lvo2 size is not approximately 400MiB"

check \'run_ssh "$NODE1_IP" "mount | grep -q "/mnt/vfatfs.*vfat""\' \
    "/mnt/vfatfs is mounted with vfat" \
    "/mnt/vfatfs is not mounted with vfat"

check \'run_ssh "$NODE1_IP" "grep -q "/mnt/vfatfs" /etc/fstab"\' \
    "/mnt/vfatfs is in /etc/fstab (persistent)" \
    "/mnt/vfatfs is not in /etc/fstab"
