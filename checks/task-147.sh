#!/usr/bin/env bash
# Task: Mount RHEL 9 ISO persistently on /mnt/cdrom, configure both repos
# Title: Mount ISO & Configure Repos
# Category: file-systems
# Target: both

# Check mount point exists
check '[[ -d /mnt/cdrom ]]' \
    "Mount point /mnt/cdrom exists" \
    "Mount point /mnt/cdrom does not exist"

# Check ISO is mounted
check 'mountpoint -q /mnt/cdrom 2>/dev/null || mount | grep -q "/mnt/cdrom"' \
    "ISO is mounted at /mnt/cdrom" \
    "Nothing mounted at /mnt/cdrom"

# Check persistent mount in fstab
check 'grep -q "/mnt/cdrom" /etc/fstab' \
    "Mount is persistent in /etc/fstab" \
    "Mount not in /etc/fstab"

# Check yum/dnf repos are configured
check 'ls /etc/yum.repos.d/*.repo 2>/dev/null | grep -q . && dnf repolist 2>/dev/null | grep -qi "baseos\|appstream\|cdrom\|local"' \
    "Yum/DNF repositories are configured" \
    "No local repositories configured"
