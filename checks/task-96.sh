#!/usr/bin/env bash
# Task: Create a 2-GiB volume group with the name myvg, using 8-MiB physical extents. In this volume group, create a 500-MiB logical volume with the name mydata, and mount it persistently on the directory /mydata
# Category: file-systems
# Target: node1

# Check volume group exists
check \'run_ssh "$NODE1_IP" "vgs myvg &>/dev/null"\' \
    "Volume group myvg exists" \
    "Volume group myvg does not exist"

# Check physical extent size is 8M
check \'run_ssh "$NODE1_IP" "vgs myvg --noheadings -o vg_extent_size 2>/dev/null | grep -q "8.00m\|8M""\' \
    "Volume group myvg has 8-MiB physical extents" \
    "Volume group myvg does not have 8-MiB extents"

# Check logical volume exists
check \'run_ssh "$NODE1_IP" "lvs myvg/mydata &>/dev/null"\' \
    "Logical volume mydata exists in myvg" \
    "Logical volume mydata does not exist"

# Check directory exists
check \'run_ssh "$NODE1_IP" "test -d /mydata"\' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"

# Check persistent mount in fstab
check \'run_ssh "$NODE1_IP" "grep -q "/mydata" /etc/fstab"\' \
    "/mydata is in /etc/fstab" \
    "/mydata is not in /etc/fstab"

# Check currently mounted
check 'mountpoint -q /mydata 2>/dev/null' \
    "/mydata is mounted" \
    "/mydata is not mounted"
