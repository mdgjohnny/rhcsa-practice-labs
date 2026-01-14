#!/usr/bin/env bash
# Task: Create a 1GB vfat filesystem with label "MYDATA" on an available loop device. Mount it persistently on /mydata.
# Title: Create VFAT Filesystem with Label
# Category: file-systems
# Target: node1

check '[[ -d /mydata ]]' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"

check 'mount | grep -q "/mydata.*vfat"' \
    "/mydata is mounted with vfat" \
    "/mydata not mounted with vfat"

check 'blkid | grep -qi "MYDATA"' \
    "Filesystem has label MYDATA" \
    "Label MYDATA not found"

check 'grep -q "/mydata" /etc/fstab' \
    "/mydata is in fstab (persistent)" \
    "/mydata not in fstab"
