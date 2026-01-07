#!/usr/bin/env bash
# Task: Create tar gzip archive of /etc, store in /var/tmp
# Title: Create tar.gz Archive
# Category: essential-tools

check 'ls /var/tmp/*.tar.gz &>/dev/null || ls /var/tmp/*.tgz &>/dev/null' \
    "A .tar.gz archive exists in /var/tmp" \
    "No .tar.gz archive found in /var/tmp"
