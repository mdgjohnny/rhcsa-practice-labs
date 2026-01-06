#!/usr/bin/env bash
# Task: Create a 4-GiB volume group, using a physical extent size of 2 MiB. In this volume group, create a 1-GiB logical volume with the name myfiles, format it with the Ext3 file system, and mount it persistently on /myfiles
# Category: file-systems
# Target: node1

# Check a volume group exists with 2M PE size
check \'run_ssh "$NODE1_IP" "vgs --noheadings -o vg_extent_size 2>/dev/null | grep -q "2.00m\|2M""\' \
    "Volume group with 2-MiB PE size exists" \
    "No volume group with 2-MiB PE size found"

# Check logical volume myfiles exists
check \'run_ssh "$NODE1_IP" "lvs 2>/dev/null | grep -q "myfiles""\' \
    "Logical volume myfiles exists" \
    "Logical volume myfiles does not exist"

# Check /myfiles directory exists
check \'run_ssh "$NODE1_IP" "test -d /myfiles"\' \
    "Directory /myfiles exists" \
    "Directory /myfiles does not exist"

# Check filesystem is ext3
check \'run_ssh "$NODE1_IP" "blkid | grep myfiles | grep -q "ext3""\' \
    "myfiles has ext3 filesystem" \
    "myfiles does not have ext3 filesystem"

# Check persistent mount
check \'run_ssh "$NODE1_IP" "grep -q "/myfiles" /etc/fstab"\' \
    "/myfiles is in /etc/fstab" \
    "/myfiles is not in /etc/fstab"

# Check currently mounted
check 'mountpoint -q /myfiles 2>/dev/null' \
    "/myfiles is mounted" \
    "/myfiles is not mounted"
