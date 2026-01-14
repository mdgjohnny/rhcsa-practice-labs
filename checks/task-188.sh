#!/usr/bin/env bash
# Task: Search for all man pages related to the keyword "password" and save the results to /root/password-manpages.txt.
# Title: Search Man Pages by Keyword
# Category: essential-tools
# Target: node1

check '[[ -f /root/password-manpages.txt ]]' \
    "File /root/password-manpages.txt exists" \
    "File /root/password-manpages.txt not found"

check '[[ -s /root/password-manpages.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qiE "passwd|shadow|crypt" /root/password-manpages.txt' \
    "File contains password-related man pages" \
    "No password-related entries found"

check '[[ $(wc -l < /root/password-manpages.txt) -ge 3 ]]' \
    "File has multiple entries" \
    "File should have more entries"
