#!/usr/bin/env bash
# Task: Create 1GiB partition, ext4, label stdlabel, mount on /mnt/stdfs1

check '[[ -d /mnt/stdfs1 ]]' \
    "Directory /mnt/stdfs1 exists" \
    "Directory /mnt/stdfs1 does not exist"

check 'mount | grep -q "/mnt/stdfs1.*ext4"' \
    "/mnt/stdfs1 is mounted with ext4" \
    "/mnt/stdfs1 is not mounted with ext4"

check 'blkid | grep -q "LABEL=\"stdlabel\""' \
    "Filesystem with label stdlabel exists" \
    "No filesystem with label stdlabel found"

check 'grep -q "stdlabel\|/mnt/stdfs1" /etc/fstab' \
    "/mnt/stdfs1 is in /etc/fstab" \
    "/mnt/stdfs1 is not in /etc/fstab"

check '[[ -f /mnt/stdfs1/stdfile1 ]]' \
    "File stdfile1 exists in /mnt/stdfs1" \
    "File stdfile1 does not exist in /mnt/stdfs1"
