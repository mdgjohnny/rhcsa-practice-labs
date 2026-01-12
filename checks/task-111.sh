#!/usr/bin/env bash
# Task: Using /dev/loop0, create VG "extendvg" and LV "extendlv" (initially 500MB). Then extend "extendlv" to 1.5GB. Resize the XFS filesystem.
# Title: Extend Logical Volume
# Category: file-systems
# Target: node1

# Check if VG exists
check 'vgs extendvg &>/dev/null' \
    "Volume group 'extendvg' exists" \
    "Volume group 'extendvg' does not exist"

# Check if LV exists and is >= 1.4GB (1400MB)
LV_SIZE=$(lvs --noheadings -o lv_size --units m extendvg/extendlv 2>/dev/null | tr -d ' m' | cut -d. -f1)
check '[[ "${LV_SIZE:-0}" -ge 1400 ]]' \
    "LV 'extendlv' is >= 1.4GB (${LV_SIZE}MB)" \
    "LV 'extendlv' is too small or missing (${LV_SIZE:-0}MB)"

# Check if mounted
check 'mount | grep -q extendlv' \
    "LV 'extendlv' is mounted" \
    "LV 'extendlv' is not mounted"
