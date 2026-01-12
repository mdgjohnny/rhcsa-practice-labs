#!/usr/bin/env bash
# Task: Mount the NFS export /data from rhcsa2 to /mnt/remote-data. Use NFSv4 and make it persistent.
# Title: Mount NFS Share with NFSv4
# Category: file-systems
# Target: node1

check '[[ -d /mnt/remote-data ]]' \
    "Mount point /mnt/remote-data exists" \
    "Mount point doesn't exist"

check 'mount | grep -q "/mnt/remote-data"' \
    "NFS share is mounted" \
    "NFS share not mounted"

check 'grep -qE "/mnt/remote-data.*nfs" /etc/fstab' \
    "Mount is persistent in fstab" \
    "Mount not in fstab"
