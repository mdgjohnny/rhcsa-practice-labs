#!/usr/bin/env bash
# Task: Create gzip-compressed tar archive of /etc directory. Store in /var/tmp.
# Title: Create Gzip Archive
# Category: essential-tools
# Target: node1

check 'ls /var/tmp/*.tar.gz &>/dev/null || ls /var/tmp/*.tgz &>/dev/null' \
    "A .tar.gz archive exists in /var/tmp" \
    "No .tar.gz archive found in /var/tmp"
