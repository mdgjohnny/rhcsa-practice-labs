#!/usr/bin/env bash
# Task: List all SELinux booleans related to FTP. Save to /root/ftp-booleans.txt.
# Title: List FTP SELinux Booleans
# Category: security
# Target: node1

check '[[ -f /root/ftp-booleans.txt ]]' \
    "File /root/ftp-booleans.txt exists" \
    "File not found"

check 'grep -qiE "ftp" /root/ftp-booleans.txt' \
    "File contains FTP-related booleans" \
    "No FTP booleans found"

check '[[ $(wc -l < /root/ftp-booleans.txt) -ge 3 ]]' \
    "File has multiple FTP booleans" \
    "Should have more FTP booleans"
