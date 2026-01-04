#!/usr/bin/env bash
# Task: Use the combination of tar and bzip2 commands to create a compressed archive of the /usr/lib directory. Store the archive under /var/tmp as usr.tar.bz2
# Category: essential-tools
# Target: node1

# Check archive exists
check '[[ -f /var/tmp/usr.tar.bz2 ]]' \
    "Archive /var/tmp/usr.tar.bz2 exists" \
    "Archive /var/tmp/usr.tar.bz2 does not exist"

# Check it's a bzip2 compressed file
check 'file /var/tmp/usr.tar.bz2 2>/dev/null | grep -qi "bzip2"' \
    "Archive is bzip2 compressed" \
    "Archive is not bzip2 compressed"

# Check archive contains /usr/lib content
check 'tar -tjf /var/tmp/usr.tar.bz2 2>/dev/null | grep -q "lib"' \
    "Archive contains lib directory content" \
    "Archive does not contain expected content"
