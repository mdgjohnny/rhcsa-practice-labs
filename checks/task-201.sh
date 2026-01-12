#!/usr/bin/env bash
# Task: Create a bzip2 compressed tar archive of /etc/ssh named /root/ssh-backup.tar.bz2.
# Title: Create bzip2 Compressed Archive
# Category: essential-tools
# Target: node1

check '[[ -f /root/ssh-backup.tar.bz2 ]]' \
    "Archive /root/ssh-backup.tar.bz2 exists" \
    "Archive not found"

check 'file /root/ssh-backup.tar.bz2 | grep -qi "bzip2"' \
    "Archive is bzip2 compressed" \
    "Archive is not bzip2 compressed"

check 'tar tjf /root/ssh-backup.tar.bz2 2>/dev/null | grep -q "sshd_config\|ssh_config"' \
    "Archive contains SSH config files" \
    "Archive doesn't contain expected files"
