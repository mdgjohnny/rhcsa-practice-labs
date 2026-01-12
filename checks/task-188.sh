#!/usr/bin/env bash
# Task: Search for all man pages related to "password" and save the list to /root/password-manpages.txt. Use apropos or man -k.
# Title: Search Man Pages with Apropos
# Category: essential-tools
# Target: node1

check '[[ -f /root/password-manpages.txt ]]' \
    "File /root/password-manpages.txt exists" \
    "File /root/password-manpages.txt not found"

check 'grep -qiE "passwd|shadow|crypt" /root/password-manpages.txt' \
    "File contains password-related man pages" \
    "No password-related entries found"

check '[[ $(wc -l < /root/password-manpages.txt) -ge 3 ]]' \
    "File has multiple entries" \
    "File should have more entries"
