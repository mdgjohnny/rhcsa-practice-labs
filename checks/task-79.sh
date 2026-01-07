#!/usr/bin/env bash
# Task: Create /root/essentials.tar with /home and /etc, copy to /tmp, hard link to /
# Title: Create Archive & Hard Link
# Category: essential-tools
# Target: node1

# Check if the archive exists
check '[[ -f /root/essentials.tar ]]' \
    "Archive /root/essentials.tar exists" \
    "Archive /root/essentials.tar does not exist"

# Check if archive contains /home and /etc
check 'tar -tf /root/essentials.tar 2>/dev/null | grep -q "^home\|^etc"' \
    "Archive contains /home and /etc directories" \
    "Archive does not contain expected directories"

# Check if copy exists in /tmp
check '[[ -f /tmp/essentials.tar ]]' \
    "Copy exists at /tmp/essentials.tar" \
    "Copy at /tmp/essentials.tar does not exist"

# Check if hard link exists in /
check '[[ -f /essentials.tar ]]' \
    "Hard link exists at /essentials.tar" \
    "Hard link at /essentials.tar does not exist"

# Verify it's actually a hard link (same inode)
check '[[ $(stat -c %i /root/essentials.tar) == $(stat -c %i /essentials.tar) ]]' \
    "/essentials.tar is a hard link to /root/essentials.tar" \
    "/essentials.tar is not a hard link (different inode)"
