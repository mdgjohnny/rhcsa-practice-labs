#!/usr/bin/env bash
# Task: Find all files owned by user edwin and copy them to /root/edwinfiles
# Category: essential-tools

check \'run_ssh "$NODE1_IP" "test -d /root/edwinfiles"\' \
    "Directory /root/edwinfiles exists" \
    "Directory /root/edwinfiles does not exist"

check '[[ $(ls -A /root/edwinfiles 2>/dev/null | wc -l) -gt 0 ]]' \
    "/root/edwinfiles contains files" \
    "/root/edwinfiles is empty"
