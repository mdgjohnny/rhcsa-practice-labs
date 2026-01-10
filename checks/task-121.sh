#!/usr/bin/env bash
# Task: Using /dev/loop0, create 4GiB VG with 2MiB physical extent size. Create 1GiB LV "myfiles" with ext3, mount on /myfiles.
# Title: Create Volume Group and Logical Volume
# Category: file-systems
# Target: node1

# Check a volume group exists with 2M PE size
check 'vgs --noheadings -o vg_extent_size 2>/dev/null | grep -q "2.00m\|2M"' \
    "Volume group with 2-MiB PE size exists" \
    "No volume group with 2-MiB PE size found"

# Check logical volume myfiles exists
check 'lvs 2>/dev/null | grep -q "myfiles"' \
    "Logical volume myfiles exists" \
    "Logical volume myfiles does not exist"

# Check /myfiles directory exists
check '[[ -d /myfiles ]]' \
    "Directory /myfiles exists" \
    "Directory /myfiles does not exist"

# Check filesystem is ext3
check 'blkid | grep myfiles | grep -q "ext3"' \
    "myfiles has ext3 filesystem" \
    "myfiles does not have ext3 filesystem"

# Check persistent mount
check 'grep -q "/myfiles" /etc/fstab' \
    "/myfiles is in /etc/fstab" \
    "/myfiles is not in /etc/fstab"

# Check currently mounted
check 'mountpoint -q /myfiles 2>/dev/null' \
    "/myfiles is mounted" \
    "/myfiles is not mounted"
