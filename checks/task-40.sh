#!/usr/bin/env bash
# Task: On rhcsa2 - Create compressed archive of /usr/lib
# Category: essential-tools
# Store as /var/tmp/usr.tar.bz2

check 'run_ssh "$NODE2_IP" "[[ -f /var/tmp/usr.tar.bz2 ]]" 2>/dev/null' \
    "Archive /var/tmp/usr.tar.bz2 exists on node2" \
    "Archive /var/tmp/usr.tar.bz2 does not exist"

check 'run_ssh "$NODE2_IP" "file /var/tmp/usr.tar.bz2 | grep -qi bzip2" 2>/dev/null' \
    "Archive is bzip2 compressed" \
    "Archive is not bzip2 compressed"
