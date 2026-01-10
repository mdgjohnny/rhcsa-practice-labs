#!/usr/bin/env bash
# Task: Create bzip2-compressed tar archive of /usr/lib. Save as /var/tmp/usr.tar.bz2
# Title: Create Compressed Archive
# Category: essential-tools
# Target: node2

check '[[ -f /var/tmp/usr.tar.bz2 ]]' \
    "Archive /var/tmp/usr.tar.bz2 exists" \
    "Archive /var/tmp/usr.tar.bz2 does not exist"

check 'file /var/tmp/usr.tar.bz2 | grep -qi bzip2' \
    "Archive is bzip2 compressed" \
    "Archive is not bzip2 compressed"
