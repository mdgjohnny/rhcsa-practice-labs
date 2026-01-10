#!/usr/bin/env bash
# Task: Create file "lnfile1" in /var/tmp with exactly 3 hard links pointing to it.
# Title: Create Hard Links
# Category: essential-tools
# Target: node2

check '[[ -f /var/tmp/lnfile1 ]]' \
    "File /var/tmp/lnfile1 exists" \
    "File /var/tmp/lnfile1 does not exist"

check '[[ -f /var/tmp/hard1 ]]' \
    "Hard link hard1 exists" \
    "Hard link hard1 does not exist"

check '[[ -f /var/tmp/hard2 ]]' \
    "Hard link hard2 exists" \
    "Hard link hard2 does not exist"

check '[[ -f /var/tmp/hard3 ]]' \
    "Hard link hard3 exists" \
    "Hard link hard3 does not exist"

check '[[ $(stat -c %i /var/tmp/lnfile1) == $(stat -c %i /var/tmp/hard1) ]]' \
    "lnfile1 and hard1 share same inode" \
    "lnfile1 and hard1 do not share same inode"
