#!/usr/bin/env bash
# Task: Find all files owned by user "edwin" and copy them to directory /root/edwinfiles/. Use cp -p to preserve attributes.
# Title: Find Files by Owner
# Category: essential-tools
# Target: node1

check '[[ -d /root/edwinfiles ]]' \
    "Directory /root/edwinfiles/ exists" \
    "Directory /root/edwinfiles/ does not exist"

check '[[ $(ls -A /root/edwinfiles 2>/dev/null | wc -l) -gt 0 ]]' \
    "Directory /root/edwinfiles/ contains files" \
    "Directory /root/edwinfiles/ is empty"
