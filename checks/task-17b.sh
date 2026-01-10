#!/usr/bin/env bash
# Task: Mount /share1 from rhcsa1 to /share2 on this host. Mount must be persistent across reboots.
# Title: Mount NFS Share
# Category: file-systems
# Target: node2

check 'mount | grep -q /share2' \
    "/share2 is mounted" \
    "/share2 is not mounted"

check 'grep -q share2 /etc/fstab' \
    "/share2 is configured in /etc/fstab (persistent)" \
    "/share2 is not in /etc/fstab (not persistent)"
