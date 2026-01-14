#!/usr/bin/env bash
# Task: Find all files owned by user "edwin" and copy them to directory /root/edwinfiles/. Preserve file attributes using cp -p.
# Title: Find Files by Owner
# Category: essential-tools
# Target: node1

check '[[ -d /root/edwinfiles ]]' \
    "Directory /root/edwinfiles/ exists" \
    "Directory /root/edwinfiles/ does not exist"

check '[[ $(ls -A /root/edwinfiles 2>/dev/null | wc -l) -ge 2 ]]' \
    "Directory /root/edwinfiles/ contains multiple files" \
    "Directory /root/edwinfiles/ is empty or has too few files"

# Verify at least one of the expected files was copied
check '[[ -f /root/edwinfiles/edwin-temp.txt ]] || [[ -f /root/edwinfiles/edwin-data.log ]] || [[ -f /root/edwinfiles/config.txt ]]' \
    "Expected edwin files were copied" \
    "Expected edwin files not found in /root/edwinfiles/"
