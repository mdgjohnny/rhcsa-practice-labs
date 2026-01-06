#!/usr/bin/env bash
# Task: As the user `student`, open a root shell and create one archive file that contains the contents of the /home directory and the /etc directory. Use the name `/root/essentials.tar` for the archive file. Copy this archive to the `/tmp` directory. Also create a hard link to this file in the `/` directory
# Category: essential-tools
# Target: node1

# Check if the archive exists
check \'run_ssh "$NODE1_IP" "test -f /root/essentials.tar"\' \
    "Archive /root/essentials.tar exists" \
    "Archive /root/essentials.tar does not exist"

# Check if archive contains /home and /etc
check \'run_ssh "$NODE1_IP" "tar -tf /root/essentials.tar 2>/dev/null | grep -q "^home\|^etc""\' \
    "Archive contains /home and /etc directories" \
    "Archive does not contain expected directories"

# Check if copy exists in /tmp
check \'run_ssh "$NODE1_IP" "test -f /tmp/essentials.tar"\' \
    "Copy exists at /tmp/essentials.tar" \
    "Copy at /tmp/essentials.tar does not exist"

# Check if hard link exists in /
check \'run_ssh "$NODE1_IP" "test -f /essentials.tar"\' \
    "Hard link exists at /essentials.tar" \
    "Hard link at /essentials.tar does not exist"

# Verify it's actually a hard link (same inode)
check '[[ $(stat -c %i /root/essentials.tar) == $(stat -c %i /essentials.tar) ]]' \
    "/essentials.tar is a hard link to /root/essentials.tar" \
    "/essentials.tar is not a hard link (different inode)"
