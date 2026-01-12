#!/usr/bin/env bash
# Task: Create an MBR (DOS) partition table on /dev/loop3 with one 300MB primary partition. Use fdisk or parted.
# Title: Create MBR Partition
# Category: local-storage
# Target: node1
# Setup: dd if=/dev/zero of=/tmp/loop3.img bs=1M count=500; losetup /dev/loop3 /tmp/loop3.img

check 'fdisk -l /dev/loop3 2>/dev/null | grep -qi "dos\|mbr" || parted /dev/loop3 print 2>/dev/null | grep -qi "msdos"' \
    "MBR/DOS partition table exists on /dev/loop3" \
    "No MBR partition table on /dev/loop3"

check 'fdisk -l /dev/loop3 2>/dev/null | grep -q "loop3p1\|loop3.*1" || lsblk /dev/loop3 2>/dev/null | grep -q "part"' \
    "Partition exists on /dev/loop3" \
    "No partition found"
