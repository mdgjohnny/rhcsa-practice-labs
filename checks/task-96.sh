#!/usr/bin/env bash
# Task: Create 2GiB VG "myvg" with 8MiB PE size. Create 500MiB LV "mydata". Mount on /mydata.
# Title: Create Volume Group and LV
# Category: file-systems
# Target: node1

# Check volume group exists
check 'vgs myvg &>/dev/null' \
    "Volume group myvg exists" \
    "Volume group myvg does not exist"

# Check physical extent size is 8M
check 'vgs myvg --noheadings -o vg_extent_size 2>/dev/null | grep -q "8.00m\|8M"' \
    "Volume group myvg has 8-MiB physical extents" \
    "Volume group myvg does not have 8-MiB extents"

# Check logical volume exists
check 'lvs myvg/mydata &>/dev/null' \
    "Logical volume mydata exists in myvg" \
    "Logical volume mydata does not exist"

# Check directory exists
check '[[ -d /mydata ]]' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"

# Check persistent mount in fstab
check 'grep -q "/mydata" /etc/fstab' \
    "/mydata is in /etc/fstab" \
    "/mydata is not in /etc/fstab"

# Check currently mounted
check 'mountpoint -q /mydata 2>/dev/null' \
    "/mydata is mounted" \
    "/mydata is not mounted"
