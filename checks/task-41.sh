#!/usr/bin/env bash
# Task: Create tar gzip archive of /etc, store in /var/tmp
# Category: essential-tools

check \'run_ssh "$NODE1_IP" "ls /var/tmp/*.tar.gz &>/dev/null || ls /var/tmp/*.tgz &>/dev/null"\' \
    "A .tar.gz archive exists in /var/tmp" \
    "No .tar.gz archive found in /var/tmp"
