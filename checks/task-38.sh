#!/usr/bin/env bash
# Task: On rhcsa2 - Create lnfile1 in /var/tmp with 3 hard links
# Title: Create Hard Links
# Category: essential-tools

check 'run_ssh "$NODE2_IP" "[[ -f /var/tmp/lnfile1 ]]" 2>/dev/null' \
    "File /var/tmp/lnfile1 exists on node2" \
    "File /var/tmp/lnfile1 does not exist on node2"

check 'run_ssh "$NODE2_IP" "[[ -f /var/tmp/hard1 ]]" 2>/dev/null' \
    "Hard link hard1 exists on node2" \
    "Hard link hard1 does not exist"

check 'run_ssh "$NODE2_IP" "[[ -f /var/tmp/hard2 ]]" 2>/dev/null' \
    "Hard link hard2 exists on node2" \
    "Hard link hard2 does not exist"

check 'run_ssh "$NODE2_IP" "[[ -f /var/tmp/hard3 ]]" 2>/dev/null' \
    "Hard link hard3 exists on node2" \
    "Hard link hard3 does not exist"

# Check they share the same inode
check 'run_ssh "$NODE2_IP" "[[ \$(stat -c %i /var/tmp/lnfile1) == \$(stat -c %i /var/tmp/hard1) ]]" 2>/dev/null' \
    "lnfile1 and hard1 share same inode" \
    "lnfile1 and hard1 do not share same inode"
